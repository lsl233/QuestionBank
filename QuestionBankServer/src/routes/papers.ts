import { Hono } from 'hono'
import { query } from '../db/index.js'
import type { Paper } from '../types/index.js'
import { listPapersQuerySchema } from '../utils/validate.js'

export const papersRouter = new Hono()

function toPaper(row: Record<string, unknown>): Paper {
  const year = String(row.year)
  const region = String(row.region)
  const subject = String(row.subject)
  const fileName = String(row.file_name)
  return {
    id: String(row.id),
    year,
    region,
    subject,
    fileName,
    title: `${year}·${region}·${subject}`,
  }
}

papersRouter.get('/', async (c) => {
  const raw = c.req.query()
  const { year, region, subject, search } = listPapersQuerySchema.parse(raw)

  const conditions: string[] = []
  const params: unknown[] = []
  let paramIndex = 0

  const pushCondition = (column: string, value: string | undefined) => {
    if (value && value !== '全部') {
      paramIndex++
      conditions.push(`${column} = $${paramIndex}`)
      params.push(value)
    }
  }

  pushCondition('year', year)
  pushCondition('region', region)
  pushCondition('subject', subject)

  if (search && search.trim()) {
    paramIndex++
    conditions.push(`file_name ILIKE $${paramIndex}`)
    params.push(`%${search.trim()}%`)
  }

  const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : ''
  const sql = `SELECT id, year, region, subject, file_name FROM papers ${whereClause} ORDER BY year DESC, region, subject`

  const result = await query(sql, params)
  const papers = result.rows.map(toPaper)
  return c.json({ papers })
})

papersRouter.get('/:id', async (c) => {
  const id = c.req.param('id')
  const result = await query(
    'SELECT id, year, region, subject, file_name FROM papers WHERE id = $1',
    [id]
  )

  if (result.rows.length === 0) {
    return c.json({ error: 'Paper not found' }, 404)
  }

  return c.json({ paper: toPaper(result.rows[0]) })
})
