import { z } from 'zod'

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
  })
  .parse(process.env)
