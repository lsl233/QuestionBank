import { Hono } from 'hono'
import { env } from '../config/env.js'
import { query } from '../db/index.js'
import type { User } from '../types/index.js'
import { verifyAppleToken, createSessionToken } from '../utils/auth.js'

export const authRouter = new Hono()

function toUser(row: Record<string, unknown>): User {
  return {
    id: String(row.id),
    appleUserId: String(row.apple_user_id),
    email: row.email ? String(row.email) : undefined,
    name: row.name ? String(row.name) : undefined,
  }
}

// 仅测试环境启用：固定测试账号一键登录
if (env.ENABLE_TEST_AUTH === 'true') {
  authRouter.post('/test-login', async (c) => {
    console.log('Received test login request')

    try {
      const testAppleUserId = 'test-user'
      const existing = await query('SELECT id, apple_user_id, email, name FROM users WHERE apple_user_id = $1', [
        testAppleUserId,
      ])

      let user: User
      if (existing.rows.length === 0) {
        const inserted = await query(
          'INSERT INTO users (apple_user_id, email, name) VALUES ($1, $2, $3) RETURNING id, apple_user_id, email, name',
          [testAppleUserId, 'test@example.com', '测试用户']
        )
        user = toUser(inserted.rows[0])
      } else {
        user = toUser(existing.rows[0])
      }

      const token = await createSessionToken(user.id)
      return c.json({ token, user })
    } catch (err) {
      console.error('Test login failed:', err)
      throw err
    }
  })
}

authRouter.post('/apple', async (c) => {
  const body = await c.req.json<{
    identityToken?: string
    email?: string
    givenName?: string
    familyName?: string
  }>()

  console.log('Received Apple login request')

  if (!body.identityToken) {
    return c.json({ error: 'identityToken is required' }, 400)
  }

  let appleUserId: string
  let email: string | undefined
  try {
    const verified = await verifyAppleToken(body.identityToken)
    appleUserId = verified.appleUserId
    email = verified.email ?? body.email
  } catch (err) {
    console.error('Apple token verification failed:', err)
    return c.json({ error: 'Invalid identity token' }, 401)
  }

  const name = [body.givenName, body.familyName].filter(Boolean).join(' ') || undefined

  const existing = await query('SELECT id, apple_user_id, email, name FROM users WHERE apple_user_id = $1', [
    appleUserId,
  ])

  let user: User
  if (existing.rows.length === 0) {
    const inserted = await query(
      'INSERT INTO users (apple_user_id, email, name) VALUES ($1, $2, $3) RETURNING id, apple_user_id, email, name',
      [appleUserId, email ?? null, name ?? null]
    )
    user = toUser(inserted.rows[0])
  } else {
    const userId = String(existing.rows[0].id)
    await query('UPDATE users SET email = $1, name = COALESCE($2, name) WHERE id = $3', [
      email ?? null,
      name ?? null,
      userId,
    ])
    user = toUser({ ...existing.rows[0], email: email ?? existing.rows[0].email, name: name || existing.rows[0].name })
  }

  const token = await createSessionToken(user.id)
  return c.json({ token, user })
})
