import 'dotenv/config'
import fs from 'node:fs/promises'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import { pool, query } from './index.js'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

const samplePapers = [
  { year: '2026', region: '上海', subject: '数学', fileName: '2026上海' },
]

const sampleNews = [
  {
    tag: '最新',
    date: '06-25',
    title: '2024 新高考 I 卷已全部上线',
    description: '语文、数学、英语、物理、化学、生物 6 科真题与答案已同步更新。',
  },
  {
    tag: '更新',
    date: '06-24',
    title: '上海卷 2024 真题已更新',
    description: '新增上海卷语文、数学、英语真题，支持在线阅读与下载。',
  },
  {
    tag: '最新',
    date: '06-23',
    title: '2024 全国甲卷理科数学上线',
    description: '全国甲卷理科数学真题与详细解析已同步更新。',
  },
]

async function run() {
  const schemaPath = path.join(__dirname, 'schema.sql')
  const schema = await fs.readFile(schemaPath, 'utf-8')
  await query(schema)

  for (const paper of samplePapers) {
    await query(
      `INSERT INTO papers (year, region, subject, file_name)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (file_name) DO NOTHING`,
      [paper.year, paper.region, paper.subject, paper.fileName]
    )
  }

  for (const news of sampleNews) {
    await query(
      `INSERT INTO news (tag, date, title, description)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (title) DO NOTHING`,
      [news.tag, news.date, news.title, news.description]
    )
  }

  console.log('Seed completed.')
  await pool.end()
}

run().catch((err) => {
  console.error(err)
  process.exit(1)
})
