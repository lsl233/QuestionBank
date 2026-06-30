import { z } from 'zod'

export const listPapersQuerySchema = z.object({
  year: z.string().optional(),
  region: z.string().optional(),
  subject: z.string().optional(),
  search: z.string().optional(),
})

export type ListPapersQuery = z.infer<typeof listPapersQuerySchema>
