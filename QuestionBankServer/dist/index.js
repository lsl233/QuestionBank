import 'dotenv/config';
import { serve } from '@hono/node-server';
import { Hono } from 'hono';
import { logger } from 'hono/logger';
import { env } from './config/env.js';
import { accountRouter } from './routes/account.js';
import { authRouter } from './routes/auth.js';
import { correctionsRouter } from './routes/corrections.js';
import { downloadsRouter } from './routes/downloads.js';
import { favoritesRouter } from './routes/favorites.js';
import { filesRouter } from './routes/files.js';
import { membershipRouter } from './routes/membership.js';
import { newsRouter } from './routes/news.js';
import { papersRouter } from './routes/papers.js';
import { privacyRouter } from './routes/privacy.js';
import { studyRecordsRouter } from './routes/studyRecords.js';
const app = new Hono();
app.use(logger());
app.route('/papers', papersRouter);
app.route('/news', newsRouter);
app.route('/files', filesRouter);
app.route('/auth', authRouter);
app.route('/account', accountRouter);
app.route('/favorites', favoritesRouter);
app.route('/membership', membershipRouter);
app.route('/downloads', downloadsRouter);
app.route('/corrections', correctionsRouter);
app.route('/study-records', studyRecordsRouter);
app.route('/privacy', privacyRouter);
app.onError((err, c) => {
    console.error(`[ERROR] ${c.req.method} ${c.req.path}`, err);
    return c.json({ error: 'Internal server error' }, 500);
});
serve({
    fetch: app.fetch,
    port: env.PORT,
}, (info) => {
    console.log(`Server is running on http://localhost:${info.port}`);
    console.log(`Test auth enabled: ${env.ENABLE_TEST_AUTH === 'true'}`);
});
