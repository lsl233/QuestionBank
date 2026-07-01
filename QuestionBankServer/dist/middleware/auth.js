import { verifySessionToken, findUserById } from '../utils/auth.js';
export function requireAuth() {
    return async (c, next) => {
        const header = c.req.header('Authorization') ?? '';
        const token = header.startsWith('Bearer ') ? header.slice(7) : header;
        if (!token) {
            return c.json({ error: 'Unauthorized' }, 401);
        }
        let userId;
        try {
            userId = await verifySessionToken(token);
        }
        catch {
            return c.json({ error: 'Unauthorized' }, 401);
        }
        const user = await findUserById(userId);
        if (!user) {
            return c.json({ error: 'Unauthorized' }, 401);
        }
        ;
        c.set('user', user);
        await next();
    };
}
