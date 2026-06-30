import { Hono } from 'hono'
import fs from 'node:fs/promises'
import { createReadStream } from 'node:fs'
import path from 'node:path'
import { env } from '../config/env.js'

export const filesRouter = new Hono()

// 仅允许字母、数字、中文以及常见连接符，防止路径遍历
const safeFileNameRegex = /^[\w一-龥\-·．.]+$/

filesRouter.get('/:name', async (c) => {
  const name = c.req.param('name')

  if (!safeFileNameRegex.test(name) || name.includes('..')) {
    return c.json({ error: 'Invalid file name' }, 400)
  }

  const filePath = path.resolve(env.FILES_DIR, `${name}.pdf`)
  const resolvedDir = path.resolve(env.FILES_DIR)

  // 确保最终路径仍在 FILES_DIR 内
  if (!filePath.startsWith(resolvedDir + path.sep)) {
    return c.json({ error: 'Invalid file path' }, 400)
  }

  try {
    const stat = await fs.stat(filePath)
    if (!stat.isFile()) {
      return c.json({ error: 'File not found' }, 404)
    }

    const utf8Name = encodeURIComponent(`${name}.pdf`)
    const fileStream = createReadStream(filePath)

    return new Response(fileStream as unknown as ReadableStream, {
      headers: {
        'Content-Type': 'application/pdf',
        'Content-Disposition': `inline; filename="paper.pdf"; filename*=UTF-8''${utf8Name}`,
        'Content-Length': stat.size.toString(),
      },
    })
  } catch (err) {
    const code = (err as NodeJS.ErrnoException).code
    if (code === 'ENOENT') {
      return c.json({ error: 'File not found' }, 404)
    }
    throw err
  }
})
