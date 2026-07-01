import { createRemoteJWKSet, jwtVerify, SignJWT } from 'jose';
import { env } from '../config/env.js';
import { query } from '../db/index.js';
const JWKS = createRemoteJWKSet(new URL('https://appleid.apple.com/auth/keys'));
function toUser(row) {
    return {
        id: String(row.id),
        appleUserId: String(row.apple_user_id),
        email: row.email ? String(row.email) : undefined,
        name: row.name ? String(row.name) : undefined,
    };
}
export async function verifyAppleToken(identityToken) {
    const { payload } = await jwtVerify(identityToken, JWKS, {
        issuer: 'https://appleid.apple.com',
        audience: env.APPLE_CLIENT_ID,
    });
    return {
        appleUserId: String(payload.sub),
        email: payload.email ? String(payload.email) : undefined,
    };
}
export async function createSessionToken(userId) {
    return new SignJWT({ userId })
        .setProtectedHeader({ alg: 'HS256' })
        .setIssuedAt()
        .setExpirationTime('30d')
        .sign(new TextEncoder().encode(env.JWT_SECRET));
}
export async function verifySessionToken(token) {
    const { payload } = await jwtVerify(token, new TextEncoder().encode(env.JWT_SECRET));
    return String(payload.userId);
}
export async function findUserById(id) {
    const result = await query('SELECT id, apple_user_id, email, name FROM users WHERE id = $1', [id]);
    if (result.rows.length === 0)
        return null;
    return toUser(result.rows[0]);
}
