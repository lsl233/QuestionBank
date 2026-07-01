import type { MiddlewareHandler } from 'hono'
import { query } from '../db/index.js'
import { findUserById, verifySessionToken } from '../utils/auth.js'

export interface MembershipContext {
  isMember: boolean
  expiresAt?: string
  isPermanent: boolean
}

async function getMembership(userId: string): Promise<MembershipContext> {
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
  const isPermanent = Boolean(row.is_permanent)
  const expiresAt = row.expires_at ? new Date(row.expires_at as string | Date).toISOString() : undefined
  const isActive = Boolean(row.is_active)

  if (!isActive) {
    return { isMember: false, isPermanent: false }
  }

  if (isPermanent) {
    return { isMember: true, expiresAt, isPermanent: true }
  }

  const now = new Date()
  const expires = expiresAt ? new Date(expiresAt) : undefined
  const isMember = !!expires && expires > now

  return { isMember, expiresAt, isPermanent: false }
}

export function requireMembership(): MiddlewareHandler {
  return async (c, next) => {
    const header = c.req.header('Authorization') ?? ''
    const token = header.startsWith('Bearer ') ? header.slice(7) : header
    if (!token) {
      return c.json({ error: 'Unauthorized' }, 401)
    }

    let userId: string
    try {
      userId = await verifySessionToken(token)
    } catch {
      return c.json({ error: 'Unauthorized' }, 401)
    }

    const user = await findUserById(userId)
    if (!user) {
      return c.json({ error: 'Unauthorized' }, 401)
    }

    ;(c as any).set('user', user)

    const membership = await getMembership(user.id)
    if (!membership.isMember) {
      return c.json({ error: 'Membership required' }, 403)
    }

    ;(c as any).set('membership', membership)
    await next()
  }
}

export async function fetchMembershipStatus(userId: string): Promise<MembershipContext> {
  return getMembership(userId)
}
