import { Hono } from 'hono'
import { requireAuth } from '../middleware/auth.js'
import { query } from '../db/index.js'
import type { User } from '../types/index.js'

export const accountRouter = new Hono()

accountRouter.delete('/', requireAuth(), async (c) => {
  const user = (c as any).get('user') as User

  const result = await query('DELETE FROM users WHERE id = $1', [user.id])

  // 幂等处理：即使用户已被删除，也返回成功
  return c.json({ success: true, alreadyDeleted: result.rowCount === 0 })
})
