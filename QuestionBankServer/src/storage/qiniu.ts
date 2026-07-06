import { createRequire } from 'node:module'
import { env } from '../config/env.js'

const require = createRequire(import.meta.url)
const qiniu: typeof import('qiniu') = require('qiniu')

if (env.QINIU_ENABLED === 'true') {
  if (!env.QINIU_ACCESS_KEY || !env.QINIU_SECRET_KEY || !env.QINIU_BUCKET || !env.QINIU_PUBLIC_DOMAIN) {
    throw new Error(
      'QINIU_ENABLED=true 时，必须配置 QINIU_ACCESS_KEY、QINIU_SECRET_KEY、QINIU_BUCKET 和 QINIU_PUBLIC_DOMAIN'
    )
  }
}

const mac = new qiniu.auth.digest.Mac(env.QINIU_ACCESS_KEY ?? '', env.QINIU_SECRET_KEY ?? '')
const config = new qiniu.conf.Config()
config.useCdnDomain = true
const bucketManager = new qiniu.rs.BucketManager(mac, config)

export function isQiniuEnabled(): boolean {
  return env.QINIU_ENABLED === 'true'
}

/**
 * 将本地相对路径统一为七牛对象 key：
 * 1. 反斜杠改为正斜杠
 * 2. 去除开头的 /
 */
export function toQiniuKey(relativePath: string): string {
  return relativePath.replace(/\\/g, '/').replace(/^\/+/, '')
}

/**
 * 为私有 Bucket 中的对象生成临时下载 URL。
 * @param key 七牛对象 key
 * @returns 带签名且在有效期内可访问的完整 URL
 */
export function generateSignedURL(key: string): string {
  const deadline = Math.floor(Date.now() / 1000) + env.QINIU_PRIVATE_URL_EXPIRES
  return bucketManager.privateDownloadUrl(env.QINIU_PUBLIC_DOMAIN!, key, deadline)
}
