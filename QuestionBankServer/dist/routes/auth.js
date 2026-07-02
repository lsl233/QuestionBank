import { Hono } from 'hono';
import { query } from '../db/index.js';
import { verifyAppleToken, createSessionToken } from '../utils/auth.js';
export const authRouter = new Hono();
function toUser(row) {
    return {
        id: String(row.id),
        appleUserId: String(row.apple_user_id),
        email: row.email ? String(row.email) : undefined,
        name: row.name ? String(row.name) : undefined,
    };
}
authRouter.post('/apple', async (c) => {
    const body = await c.req.json();
    console.log('Received Apple login request:', body);
    if (!body.identityToken) {
        return c.json({ error: 'identityToken is required' }, 400);
    }
    let appleUserId;
    let email;
    try {
        const verified = await verifyAppleToken(body.identityToken);
        appleUserId = verified.appleUserId;
        email = verified.email ?? body.email;
    }
    catch (err) {
        console.error('Apple token verification failed:', err);
        return c.json({ error: 'Invalid identity token' }, 401);
    }
    const name = [body.givenName, body.familyName].filter(Boolean).join(' ') || undefined;
    const existing = await query('SELECT id, apple_user_id, email, name FROM users WHERE apple_user_id = $1', [
        appleUserId,
    ]);
    let user;
    if (existing.rows.length === 0) {
        const inserted = await query('INSERT INTO users (apple_user_id, email, name) VALUES ($1, $2, $3) RETURNING id, apple_user_id, email, name', [appleUserId, email ?? null, name ?? null]);
        user = toUser(inserted.rows[0]);
    }
    else {
        const userId = String(existing.rows[0].id);
        await query('UPDATE users SET email = $1, name = COALESCE($2, name) WHERE id = $3', [
            email ?? null,
            name ?? null,
            userId,
        ]);
        user = toUser({ ...existing.rows[0], email: email ?? existing.rows[0].email, name: name || existing.rows[0].name });
    }
    const token = await createSessionToken(user.id);
    return c.json({ token, user });
});
