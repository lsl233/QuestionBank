import { z } from 'zod'

export const env = z
  .object({
    DATABASE_URL: z.string().url(),
    PORT: z.string().transform(Number).default('3000'),
    FILES_DIR: z.string().default('./files'),
  })
  .parse(process.env)
