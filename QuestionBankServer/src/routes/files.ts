import { Hono } from 'hono'
import fs from 'node:fs/promises'
import { createReadStream } from 'node:fs'
import path from 'node:path'
import { env } from '../config/env.js'
import { query } from '../db/index.js'
import { requireMembership } from '../middleware/membership.js'
import { generateSignedURL, isQiniuEnabled, toQiniuKey } from '../storage/qiniu.js'

export const filesRouter = new Hono()

// 文件名仅允许字母、数字、中文以及常见连接符
const safeFileNameRegex = /^[\w一-龥\-·．.]+$/

function isInsideFilesDir(targetPath: string): boolean {
  const resolvedDir = path.resolve(env.FILES_DIR)
  return targetPath.startsWith(resolvedDir + path.sep) || targetPath === resolvedDir
}

async function resolvePaperFile(name: string): Promise<{ relativePath: string; absolutePath: string } | null> {
  if (!safeFileNameRegex.test(name) || name.includes('..')) {
    return null
  }

  const dbResult = await query(
    `SELECT pf.file_path
     FROM paper_files pf
     JOIN papers p ON p.id = pf.paper_id
     WHERE pf.file_type = 'exam_paper' AND p.file_name = $1
     LIMIT 1`,
    [name]
  )

  if (dbResult.rows.length === 0) {
    return null
  }

  const relativePath = String(dbResult.rows[0].file_path)
  return {
    relativePath,
    absolutePath: path.resolve(env.FILES_DIR, relativePath),
  }
}

async function serveLocalFile(c: any, filePath: string, defaultName?: string): Promise<Response> {
  const resolved = path.resolve(filePath)
  if (!isInsideFilesDir(resolved)) {
    return c.json({ error: 'Invalid file path' }, 400)
  }

  const stat = await fs.stat(resolved)
  if (!stat.isFile()) {
    return c.json({ error: 'File not found' }, 404)
  }

  const ext = path.extname(resolved).toLowerCase()
  const contentType =
    ext === '.pdf'
      ? 'application/pdf'
      : ext === '.mp3'
        ? 'audio/mpeg'
        : ext === '.m4a'
          ? 'audio/mp4'
          : ext === '.txt' || ext === '.md'
            ? 'text/plain; charset=utf-8'
            : 'application/octet-stream'

  const baseName = defaultName ?? path.basename(resolved)
  const asciiName = `file${ext}`
  const utf8Name = encodeURIComponent(baseName)
  const fileStream = createReadStream(resolved)

  return new Response(fileStream as unknown as ReadableStream, {
    headers: {
      'Content-Type': contentType,
      'Content-Disposition': `inline; filename="${asciiName}"; filename*=UTF-8''${utf8Name}`,
      'Content-Length': stat.size.toString(),
    },
  })
}

function redirectToSignedURL(c: any, key: string): Response {
  const signedURL = generateSignedURL(key)
  return c.redirect(signedURL, 302)
}

// 预览接口：不校验会员/登录，用于 App 内查看 PDF
filesRouter.get('/:name/preview', async (c) => {
  const name = c.req.param('name')
  const file = await resolvePaperFile(name)

  if (!file) {
    return c.json({ error: 'File not found' }, 404)
  }

  if (isQiniuEnabled()) {
    return redirectToSignedURL(c, toQiniuKey(file.relativePath))
  }

  return serveLocalFile(c, file.absolutePath, `${name}.pdf`)
})

// 下载接口：需要会员，代表「保存/分享」行为
filesRouter.use('/:name', requireMembership())
filesRouter.get('/:name', async (c) => {
  const name = c.req.param('name')
  const file = await resolvePaperFile(name)

  if (!file) {
    return c.json({ error: 'File not found' }, 404)
  }

  if (isQiniuEnabled()) {
    return redirectToSignedURL(c, toQiniuKey(file.relativePath))
  }

  return serveLocalFile(c, file.absolutePath, `${name}.pdf`)
})

// 按相对路径直接访问任意文件
filesRouter.use('/raw/:path{.+}', requireMembership())
filesRouter.get('/raw/:path{.+}', async (c) => {
  const rawPath = c.req.param('path')
  if (rawPath.includes('..')) {
    return c.json({ error: 'Invalid file path' }, 400)
  }

  if (isQiniuEnabled()) {
    return redirectToSignedURL(c, toQiniuKey(rawPath))
  }

  const filePath = path.resolve(env.FILES_DIR, rawPath)
  return serveLocalFile(c, filePath)
})
