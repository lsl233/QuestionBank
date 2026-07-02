import { Hono } from 'hono';
import { query } from '../db/index.js';
import { requireAuth } from '../middleware/auth.js';
export const favoritesRouter = new Hono();
function getUser(c) {
    return c.get('user');
}
function toPaper(row) {
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
        createdAt: row.paper_created_at ? new Date(row.paper_created_at).toISOString() : '',
    };
}
function toFavorite(row, paper) {
    return {
        id: String(row.favorite_id),
        userId: String(row.user_id),
        paperId: String(row.id),
        paper,
        createdAt: String(row.created_at),
    };
}
favoritesRouter.use('*', requireAuth());
favoritesRouter.get('/', async (c) => {
    const user = getUser(c);
    const result = await query(`SELECT f.id AS favorite_id, f.user_id, f.created_at,
            p.id AS id, p.year, p.exam_type, p.region, p.subject, p.stream, p.note, p.file_name, p.title, p.view_count, p.created_at AS paper_created_at
     FROM favorites f
     JOIN papers p ON p.id = f.paper_id
     WHERE f.user_id = $1
     ORDER BY f.created_at DESC`, [user.id]);
    const favorites = result.rows.map((row) => {
        const paper = toPaper(row);
        return toFavorite(row, paper);
    });
    return c.json({ favorites });
});
favoritesRouter.post('/', async (c) => {
    const user = getUser(c);
    const body = await c.req.json();
    if (!body.paperId) {
        return c.json({ error: 'paperId is required' }, 400);
    }
    const paperResult = await query('SELECT id FROM papers WHERE id = $1', [body.paperId]);
    if (paperResult.rows.length === 0) {
        return c.json({ error: 'Paper not found' }, 404);
    }
    await query(`INSERT INTO favorites (user_id, paper_id) VALUES ($1, $2)
     ON CONFLICT (user_id, paper_id) DO NOTHING`, [user.id, body.paperId]);
    return c.json({ success: true });
});
favoritesRouter.delete('/:paperId', async (c) => {
    const user = getUser(c);
    const paperId = c.req.param('paperId');
    await query('DELETE FROM favorites WHERE user_id = $1 AND paper_id = $2', [user.id, paperId]);
    return c.json({ success: true });
});
