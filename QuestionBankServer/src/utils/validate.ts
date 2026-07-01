import { z } from 'zod'

export const listPapersQuerySchema = z.object({
  year: z.string().optional(),
  region: z.string().optional(),
  subject: z.string().optional(),
  search: z.string().optional(),
  page: z.coerce.number().int().positive().optional(),
  limit: z.coerce.number().int().positive().max(100).optional(),
})

export type ListPapersQuery = z.infer<typeof listPapersQuerySchema>
