import type { MiddlewareHandler } from 'hono'
import { verifySessionToken, findUserById } from '../utils/auth.js'

export function requireAuth(): MiddlewareHandler {
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
    await next()
  }
}
