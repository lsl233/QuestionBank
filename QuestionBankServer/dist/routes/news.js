import { Hono } from 'hono';
import { query } from '../db/index.js';
export const newsRouter = new Hono();
function toNewsItem(row) {
    return {
        id: String(row.id),
        tag: String(row.tag),
        date: String(row.date),
        title: String(row.title),
        description: String(row.description),
    };
}
newsRouter.get('/', async (c) => {
    const result = await query('SELECT id, tag, date, title, description FROM news ORDER BY created_at DESC');
    const news = result.rows.map(toNewsItem);
    return c.json({ news });
});
