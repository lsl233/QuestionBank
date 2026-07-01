import { Hono } from 'hono'
import { query } from '../db/index.js'
import { requireAuth } from '../middleware/auth.js'
import { verifyAppleTransaction, verifyAppleNotification } from '../utils/appleIap.js'
import type { MembershipProduct, User } from '../types/index.js'

export const membershipRouter = new Hono()

const FAR_FUTURE = new Date('9999-12-31T23:59:59.999Z')

function toMembershipProduct(row: Record<string, unknown>): MembershipProduct {
  return {
    id: String(row.id),
    appleProductId: String(row.apple_product_id),
    name: String(row.name),
    durationDays: row.duration_days === null ? null : Number(row.duration_days),
    isPermanent: row.is_permanent === true,
  }
}

interface MembershipStatus {
  isMember: boolean
  expiresAt?: string
  isPermanent: boolean
}

async function getMembershipStatus(userId: string): Promise<MembershipStatus> {
  const result = await query(
    `SELECT um.is_active, um.expires_at, mp.is_permanent
     FROM user_memberships um
     LEFT JOIN membership_products mp ON mp.id = um.last_product_id
     WHERE um.user_id = $1`,
    [userId]
  )

  if (result.rows.length === 0) {
    return { isMember: false, isPermanent: false }
  }

  const row = result.rows[0]
  const isPermanent = row.is_permanent === true
  const expiresAt = row.expires_at ? new Date(row.expires_at as string | Date).toISOString() : undefined
  const isActive = row.is_active === true

  if (isPermanent) {
    return { isMember: isActive, expiresAt, isPermanent: true }
  }

  const now = new Date()
  const expires = expiresAt ? new Date(expiresAt) : undefined
  const isMember = isActive && !!expires && expires > now

  return { isMember, expiresAt, isPermanent: false }
}

async function recomputeMembership(userId: string): Promise<void> {
  const result = await query(
    `SELECT t.product_id, mp.is_permanent, t.expires_at
     FROM apple_transactions t
     JOIN membership_products mp ON mp.id = t.product_id
     WHERE t.user_id = $1 AND t.revoked_at IS NULL
     ORDER BY mp.is_permanent DESC, t.expires_at DESC NULLS LAST
     LIMIT 1`,
    [userId]
  )

  const now = new Date()
  let isActive = false
  let expiresAt: Date | null = null
  let lastProductId: string | null = null

  if (result.rows.length > 0) {
    const row = result.rows[0]
    const isPermanent = row.is_permanent === true
    lastProductId = String(row.product_id)

    if (isPermanent) {
      isActive = true
      expiresAt = FAR_FUTURE
    } else if (row.expires_at) {
      expiresAt = new Date(String(row.expires_at))
      if (expiresAt > now) {
        isActive = true
      }
    }
  }

  await query(
    `INSERT INTO user_memberships (user_id, is_active, expires_at, last_product_id, updated_at)
     VALUES ($1, $2, $3, $4, NOW())
     ON CONFLICT (user_id) DO UPDATE SET
       is_active = EXCLUDED.is_active,
       expires_at = EXCLUDED.expires_at,
       last_product_id = EXCLUDED.last_product_id,
       updated_at = NOW()`,
    [userId, isActive, expiresAt ? expiresAt.toISOString() : null, lastProductId]
  )
}

membershipRouter.get('/products', async (c) => {
  const result = await query(
    `SELECT id, apple_product_id, name, duration_days, is_permanent
     FROM membership_products
     ORDER BY created_at`
  )
  return c.json({ products: result.rows.map(toMembershipProduct) })
})

membershipRouter.get('/status', requireAuth(), async (c) => {
  const user = (c as any).get('user') as User
  const status = await getMembershipStatus(user.id)
  return c.json(status)
})

membershipRouter.post('/apple/verify', requireAuth(), async (c) => {
  const user = (c as any).get('user') as User
  const body = await c.req.json<{ signedTransactionJws?: string }>()

  if (!body.signedTransactionJws) {
    return c.json({ error: 'signedTransactionJws is required' }, 400)
  }

  let transaction
  try {
    transaction = await verifyAppleTransaction(body.signedTransactionJws)
  } catch (err) {
    console.error('Apple transaction verification failed:', err)
    return c.json({ error: 'Invalid transaction' }, 400)
  }

  if (transaction.revokedAt) {
    return c.json({ error: 'Transaction has been revoked' }, 400)
  }

  const productResult = await query(
    'SELECT id, duration_days, is_permanent FROM membership_products WHERE apple_product_id = $1',
    [transaction.productId]
  )
  if (productResult.rows.length === 0) {
    return c.json({ error: 'Unknown product' }, 400)
  }

  const product = productResult.rows[0]

  const existingTx = await query('SELECT user_id FROM apple_transactions WHERE transaction_id = $1', [
    transaction.transactionId,
  ])
  if (existingTx.rows.length > 0) {
    if (String(existingTx.rows[0].user_id) !== user.id) {
      return c.json({ error: 'Transaction already used by another user' }, 400)
    }
    await recomputeMembership(user.id)
    const status = await getMembershipStatus(user.id)
    return c.json({ success: true, membership: status })
  }

  const productId = String(product.id)
  const purchasedAt = transaction.purchasedAt
  let transactionExpiresAt: Date

  if (product.is_permanent === true) {
    transactionExpiresAt = FAR_FUTURE
  } else {
    const durationDays = Number(product.duration_days)
    if (!durationDays || durationDays <= 0) {
      return c.json({ error: 'Invalid product duration' }, 400)
    }

    const membershipResult = await query('SELECT expires_at FROM user_memberships WHERE user_id = $1', [user.id])
    const now = new Date()
    let base = now
    if (membershipResult.rows.length > 0 && membershipResult.rows[0].expires_at) {
      const current = new Date(String(membershipResult.rows[0].expires_at))
      if (current > now) {
        base = current
      }
    }

    transactionExpiresAt = new Date(base.getTime() + durationDays * 24 * 60 * 60 * 1000)
  }

  await query(
    `INSERT INTO apple_transactions
       (user_id, product_id, transaction_id, original_transaction_id, signed_transaction_jws, purchased_at, expires_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
    [
      user.id,
      productId,
      transaction.transactionId,
      transaction.originalTransactionId,
      body.signedTransactionJws,
      purchasedAt,
      transactionExpiresAt.toISOString(),
    ]
  )

  await recomputeMembership(user.id)
  const status = await getMembershipStatus(user.id)
  return c.json({ success: true, membership: status })
})

membershipRouter.post('/apple/notify', async (c) => {
  const body = await c.req.json<{ signedPayload?: string }>()

  if (!body.signedPayload) {
    return c.json({ error: 'signedPayload is required' }, 400)
  }

  let notification
  try {
    notification = await verifyAppleNotification(body.signedPayload)
  } catch (err) {
    console.error('Apple notification verification failed:', err)
    return c.json({ error: 'Invalid notification' }, 400)
  }

  const { notificationType, transaction } = notification

  if (!transaction) {
    return c.json({ ok: true })
  }

  if (notificationType === 'REFUND' || notificationType === 'REVOKE') {
    await query('UPDATE apple_transactions SET revoked_at = NOW() WHERE transaction_id = $1', [
      transaction.transactionId,
    ])
    const txRow = await query('SELECT user_id FROM apple_transactions WHERE transaction_id = $1', [
      transaction.transactionId,
    ])
    if (txRow.rows.length > 0) {
      await recomputeMembership(String(txRow.rows[0].user_id))
    }
  } else if (notificationType === 'REFUND_REVERSED') {
    await query('UPDATE apple_transactions SET revoked_at = NULL WHERE transaction_id = $1', [
      transaction.transactionId,
    ])
    const txRow = await query('SELECT user_id FROM apple_transactions WHERE transaction_id = $1', [
      transaction.transactionId,
    ])
    if (txRow.rows.length > 0) {
      await recomputeMembership(String(txRow.rows[0].user_id))
    }
  }

  return c.json({ ok: true })
})
