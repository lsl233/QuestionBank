import { Hono } from 'hono'
import { query } from '../db/index.js'
import type { Correction, Paper, User } from '../types/index.js'
import { requireAuth } from '../middleware/auth.js'

export const correctionsRouter = new Hono()

function getUser(c: any): User {
  return c.get('user') as User
}

function toPaper(row: Record<string, unknown>): Paper {
  return {
    id: String(row.id),
    year: String(row.year),
    examType: String(row.exam_type),
    region: String(row.region),
    subject: String(row.subject),
    stream: row.stream ? String(row.stream) : undefined,
    note: row.note ? String(row.note) : undefined,
    fileName: String(row.file_name),
    title: String(row.title),
    viewCount: row.view_count ? Number(row.view_count) : 0,
  }
}

function toCorrection(row: Record<string, unknown>, paper?: Paper): Correction {
  return {
    id: String(row.correction_id),
    userId: String(row.user_id),
    paperId: String(row.id),
    paper,
    content: String(row.content),
    status: String(row.status) as 'pending' | 'resolved' | 'ignored',
    createdAt: String(row.created_at),
    updatedAt: String(row.updated_at),
  }
}

correctionsRouter.use('*', requireAuth())

correctionsRouter.get('/', async (c) => {
  const user = getUser(c)
  const result = await query(
    `SELECT c.id AS correction_id, c.user_id, c.content, c.status, c.created_at, c.updated_at,
            p.id AS id, p.year, p.exam_type, p.region, p.subject, p.stream, p.note, p.file_name, p.title, p.view_count
     FROM corrections c
     JOIN papers p ON p.id = c.paper_id
     WHERE c.user_id = $1
     ORDER BY c.created_at DESC`,
    [user.id]
  )
  const corrections = result.rows.map((row) => {
    const paper = toPaper(row)
    return toCorrection(row, paper)
  })
  return c.json({ corrections })
})

correctionsRouter.post('/', async (c) => {
  const user = getUser(c)
  const body = await c.req.json<{ paperId?: string; content?: string }>()
  if (!body.paperId) {
    return c.json({ error: 'paperId is required' }, 400)
  }
  if (!body.content || body.content.trim().length === 0) {
    return c.json({ error: 'content is required' }, 400)
  }

  const paperResult = await query('SELECT id FROM papers WHERE id = $1', [body.paperId])
  if (paperResult.rows.length === 0) {
    return c.json({ error: 'Paper not found' }, 404)
  }

  await query(
    'INSERT INTO corrections (user_id, paper_id, content) VALUES ($1, $2, $3)',
    [user.id, body.paperId, body.content.trim()]
  )

  return c.json({ success: true })
})

correctionsRouter.get('/count', async (c) => {
  const user = getUser(c)
  const result = await query('SELECT COUNT(*) AS total FROM corrections WHERE user_id = $1', [user.id])
  return c.json({ count: Number(result.rows[0].total) })
})
