import { Hono } from 'hono';
import { query } from '../db/index.js';
import { requireMembership } from '../middleware/membership.js';
import { listPapersQuerySchema } from '../utils/validate.js';
export const papersRouter = new Hono();
function toPaper(row) {
    const year = String(row.year);
    const examType = String(row.exam_type);
    const region = String(row.region);
    const subject = String(row.subject);
    const stream = row.stream ? String(row.stream) : undefined;
    const note = row.note ? String(row.note) : undefined;
    const fileName = String(row.file_name);
    const title = String(row.title);
    return {
        id: String(row.id),
        year,
        examType,
        region,
        subject,
        stream,
        note,
        fileName,
        title,
        viewCount: row.view_count ? Number(row.view_count) : 0,
        createdAt: row.created_at ? new Date(row.created_at).toISOString() : '',
    };
}
function toPaperFile(row) {
    return {
        id: String(row.id),
        paperId: String(row.paper_id),
        fileType: String(row.file_type),
        filePath: String(row.file_path),
        mimeType: row.mime_type ? String(row.mime_type) : undefined,
        sizeBytes: row.size_bytes ? Number(row.size_bytes) : undefined,
    };
}
papersRouter.get('/', async (c) => {
    const raw = c.req.query();
    const { year, region, subject, search, page, limit } = listPapersQuerySchema.parse(raw);
    const conditions = [];
    const params = [];
    let paramIndex = 0;
    const pushCondition = (column, value) => {
        if (value && value !== '全部') {
            paramIndex++;
            conditions.push(`${column} = $${paramIndex}`);
            params.push(value);
        }
    };
    pushCondition('year', year);
    pushCondition('region', region);
    pushCondition('subject', subject);
    if (search && search.trim()) {
        paramIndex++;
        const term = `%${search.trim()}%`;
        conditions.push(`(file_name ILIKE $${paramIndex} OR title ILIKE $${paramIndex} OR region ILIKE $${paramIndex})`);
        params.push(term);
    }
    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(' AND ')}` : '';
    const currentPage = page && page > 0 ? page : 1;
    const pageSize = limit && limit > 0 && limit <= 100 ? limit : 20;
    const offset = (currentPage - 1) * pageSize;
    const countSql = `SELECT COUNT(*) AS total FROM papers ${whereClause}`;
    const countResult = await query(countSql, params);
    const total = Number(countResult.rows[0].total);
    paramIndex++;
    const pagedParams = [...params, pageSize, offset];
    const dataSql = `SELECT id, year, exam_type, region, subject, stream, note, file_name, title, view_count, created_at
                   FROM papers ${whereClause}
                   ORDER BY year DESC, region, subject
                   LIMIT $${paramIndex} OFFSET $${paramIndex + 1}`;
    const result = await query(dataSql, pagedParams);
    const papers = result.rows.map(toPaper);
    return c.json({ papers, total, page: currentPage, limit: pageSize });
});
papersRouter.get('/:id', async (c) => {
    const id = c.req.param('id');
    const result = await query(`UPDATE papers
     SET view_count = view_count + 1
     WHERE id = $1
     RETURNING id, year, exam_type, region, subject, stream, note, file_name, title, view_count, created_at`, [id]);
    if (result.rows.length === 0) {
        return c.json({ error: 'Paper not found' }, 404);
    }
    return c.json({ paper: toPaper(result.rows[0]) });
});
papersRouter.get('/:id/files', requireMembership(), async (c) => {
    const id = c.req.param('id');
    const paperResult = await query('SELECT id FROM papers WHERE id = $1', [id]);
    if (paperResult.rows.length === 0) {
        return c.json({ error: 'Paper not found' }, 404);
    }
    const result = await query('SELECT id, paper_id, file_type, file_path, mime_type, size_bytes FROM paper_files WHERE paper_id = $1 ORDER BY file_type', [id]);
    const files = result.rows.map(toPaperFile);
    return c.json({ files });
});
