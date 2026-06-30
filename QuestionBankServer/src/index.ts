import 'dotenv/config'
import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import { env } from './config/env.js'
import { filesRouter } from './routes/files.js'
import { newsRouter } from './routes/news.js'
import { papersRouter } from './routes/papers.js'

const app = new Hono()

app.route('/papers', papersRouter)
app.route('/news', newsRouter)
app.route('/files', filesRouter)

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
