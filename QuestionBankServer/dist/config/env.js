import { z } from 'zod';
export const env = z
    .object({
    DATABASE_URL: z.string().url(),
    PORT: z.coerce.number().default(3000),
    FILES_DIR: z.string().default('./files'),
    JWT_SECRET: z.string().min(1),
    APPLE_CLIENT_ID: z.string().min(1),
    APPLE_IAP_ENV: z.enum(['sandbox', 'production']).default('sandbox'),
    APPLE_ROOT_CA_DIR: z.string().default('./certs'),
    APPLE_IAP_SKIP_VERIFY: z.enum(['true', 'false']).default('false'),
    ENABLE_TEST_AUTH: z.enum(['true', 'false']).default('false'),
    // 七牛云对象存储：私有 Bucket + 后端签发临时签名 URL
    QINIU_ENABLED: z.enum(['true', 'false']).default('false'),
    QINIU_ACCESS_KEY: z.string().optional(),
    QINIU_SECRET_KEY: z.string().optional(),
    QINIU_BUCKET: z.string().optional(),
    QINIU_PUBLIC_DOMAIN: z.string().url().optional(),
    QINIU_PRIVATE_URL_EXPIRES: z.coerce.number().default(3600),
})
    .parse(process.env);
