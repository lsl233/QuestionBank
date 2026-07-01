import { Hono } from 'hono'
import { query } from '../db/index.js'
import type { StudyRecord, Paper, User } from '../types/index.js'
import { requireAuth } from '../middleware/auth.js'

export const studyRecordsRouter = new Hono()

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

function toStudyRecord(row: Record<string, unknown>, paper?: Paper): StudyRecord {
  return {
    id: String(row.record_id),
    userId: String(row.user_id),
    paperId: String(row.id),
    paper,
    viewedAt: String(row.viewed_at),
    durationSec: row.duration_sec ? Number(row.duration_sec) : 0,
  }
}

studyRecordsRouter.use('*', requireAuth())

studyRecordsRouter.get('/', async (c) => {
  const user = getUser(c)
  const result = await query(
    `SELECT s.id AS record_id, s.user_id, s.viewed_at, s.duration_sec,
            p.id AS id, p.year, p.exam_type, p.region, p.subject, p.stream, p.note, p.file_name, p.title, p.view_count
     FROM study_records s
     JOIN papers p ON p.id = s.paper_id
     WHERE s.user_id = $1
     ORDER BY s.viewed_at DESC`,
    [user.id]
  )
  const records = result.rows.map((row) => {
    const paper = toPaper(row)
    return toStudyRecord(row, paper)
  })
  return c.json({ records })
})

studyRecordsRouter.post('/', async (c) => {
  const user = getUser(c)
  const body = await c.req.json<{ paperId?: string; durationSec?: number }>()
  if (!body.paperId) {
    return c.json({ error: 'paperId is required' }, 400)
  }

  const paperResult = await query('SELECT id FROM papers WHERE id = $1', [body.paperId])
  if (paperResult.rows.length === 0) {
    return c.json({ error: 'Paper not found' }, 404)
  }

  const duration = body.durationSec ?? 0
  await query(
    `INSERT INTO study_records (user_id, paper_id, duration_sec) VALUES ($1, $2, $3)
     ON CONFLICT (user_id, paper_id) DO UPDATE SET viewed_at = NOW(), duration_sec = GREATEST(study_records.duration_sec, EXCLUDED.duration_sec)`,
    [user.id, body.paperId, duration]
  )

  return c.json({ success: true })
})

studyRecordsRouter.get('/count', async (c) => {
  const user = getUser(c)
  const result = await query('SELECT COUNT(*) AS total FROM study_records WHERE user_id = $1', [user.id])
  return c.json({ count: Number(result.rows[0].total) })
})
