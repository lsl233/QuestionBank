import { Hono } from 'hono'
import { query } from '../db/index.js'
import type { Download, Paper, User } from '../types/index.js'
import { requireAuth } from '../middleware/auth.js'

export const downloadsRouter = new Hono()

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
    createdAt: row.paper_created_at ? new Date(row.paper_created_at as string | number | Date).toISOString() : '',
  }
}

function toDownload(row: Record<string, unknown>, paper?: Paper): Download {
  return {
    id: String(row.download_id),
    userId: String(row.user_id),
    paperId: String(row.id),
    paper,
    createdAt: String(row.created_at),
  }
}

downloadsRouter.use('*', requireAuth())

downloadsRouter.get('/', async (c) => {
  const user = getUser(c)
  const result = await query(
    `SELECT d.id AS download_id, d.user_id, d.created_at,
            p.id AS id, p.year, p.exam_type, p.region, p.subject, p.stream, p.note, p.file_name, p.title, p.view_count, p.created_at AS paper_created_at
     FROM downloads d
     JOIN papers p ON p.id = d.paper_id
     WHERE d.user_id = $1
     ORDER BY d.created_at DESC`,
    [user.id]
  )
  const downloads = result.rows.map((row) => {
    const paper = toPaper(row)
    return toDownload(row, paper)
  })
  return c.json({ downloads })
})

downloadsRouter.post('/', async (c) => {
  const user = getUser(c)
  const body = await c.req.json<{ paperId?: string }>()
  if (!body.paperId) {
    return c.json({ error: 'paperId is required' }, 400)
  }

  const paperResult = await query('SELECT id FROM papers WHERE id = $1', [body.paperId])
  if (paperResult.rows.length === 0) {
    return c.json({ error: 'Paper not found' }, 404)
  }

  await query(
    `INSERT INTO downloads (user_id, paper_id) VALUES ($1, $2)
     ON CONFLICT (user_id, paper_id) DO UPDATE SET created_at = NOW()`,
    [user.id, body.paperId]
  )

  return c.json({ success: true })
})

downloadsRouter.get('/count', async (c) => {
  const user = getUser(c)
  const result = await query('SELECT COUNT(*) AS total FROM downloads WHERE user_id = $1', [user.id])
  return c.json({ count: Number(result.rows[0].total) })
})
