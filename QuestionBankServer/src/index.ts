import 'dotenv/config'
import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import { env } from './config/env.js'
import { authRouter } from './routes/auth.js'
import { correctionsRouter } from './routes/corrections.js'
import { downloadsRouter } from './routes/downloads.js'
import { favoritesRouter } from './routes/favorites.js'
import { filesRouter } from './routes/files.js'
import { membershipRouter } from './routes/membership.js'
import { newsRouter } from './routes/news.js'
import { papersRouter } from './routes/papers.js'
import { studyRecordsRouter } from './routes/studyRecords.js'

const app = new Hono()

app.route('/papers', papersRouter)
app.route('/news', newsRouter)
app.route('/files', filesRouter)
app.route('/auth', authRouter)
app.route('/favorites', favoritesRouter)
app.route('/membership', membershipRouter)
app.route('/downloads', downloadsRouter)
app.route('/corrections', correctionsRouter)
app.route('/study-records', studyRecordsRouter)

app.onError((err, c) => {
  console.error(err)
  return c.json({ error: 'Internal server error' }, 500)
})

serve(
  {
    fetch: app.fetch,
    port: env.PORT,
  },
  (info) => {
    console.log(`Server is running on http://localhost:${info.port}`)
  }
)
