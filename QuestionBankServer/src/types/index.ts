export interface Paper {
  id: string
  year: string
  examType: string
  region: string
  subject: string
  stream?: string
  note?: string
  fileName: string
  title: string
  viewCount: number
}

export interface PaperFile {
  id: string
  paperId: string
  fileType: string
  filePath: string
  mimeType?: string
  sizeBytes?: number
  downloadUrl?: string
}

export interface User {
  id: string
  appleUserId?: string
  email?: string
  name?: string
}

export interface Favorite {
  id: string
  userId: string
  paperId: string
  paper?: Paper
  createdAt: string
}

export interface Download {
  id: string
  userId: string
  paperId: string
  paper?: Paper
  createdAt: string
}

export interface Correction {
  id: string
  userId: string
  paperId: string
  paper?: Paper
  content: string
  status: 'pending' | 'resolved' | 'ignored'
  createdAt: string
  updatedAt: string
}

export interface StudyRecord {
  id: string
  userId: string
  paperId: string
  paper?: Paper
  viewedAt: string
  durationSec: number
}

export interface NewsItem {
  id: string
  tag: string
  date: string
  title: string
  description: string
}

export interface MembershipProduct {
  id: string
  appleProductId: string
  name: string
  durationDays: number | null
  isPermanent: boolean
}

export interface Membership {
  userId: string
  isActive: boolean
  expiresAt?: string
  isPermanent: boolean
  productId?: string
}

export interface AppleTransaction {
  id: string
  userId: string
  productId: string
  transactionId: string
  originalTransactionId: string
  signedTransactionJws: string
  purchasedAt: string
  expiresAt?: string
  revokedAt?: string
}
