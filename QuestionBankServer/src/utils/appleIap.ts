import { SignedDataVerifier, Environment } from '@apple/app-store-server-library'
import type { JWSTransactionDecodedPayload } from '@apple/app-store-server-library/dist/models/JWSTransactionDecodedPayload.js'
import type { ResponseBodyV2DecodedPayload } from '@apple/app-store-server-library/dist/models/ResponseBodyV2DecodedPayload.js'
import fs from 'node:fs'
import path from 'node:path'
import { env } from '../config/env.js'

let verifier: SignedDataVerifier | null = null

function createVerifier(): SignedDataVerifier {
  const certsDir = path.resolve(env.APPLE_ROOT_CA_DIR)
  const certFiles = fs
    .readdirSync(certsDir)
    .filter((name) => /\.(cer|crt|der|pem)$/i.test(name))
    .map((name) => path.join(certsDir, name))

  if (certFiles.length === 0 && env.APPLE_IAP_SKIP_VERIFY !== 'true') {
    throw new Error(`No Apple root certificates found in ${certsDir}. Download them from https://www.apple.com/certificateauthority/ or set APPLE_IAP_SKIP_VERIFY=true for development.`)
  }

  const certificates = certFiles.map((file) => fs.readFileSync(file))
  const environment = env.APPLE_IAP_ENV === 'production' ? Environment.PRODUCTION : Environment.SANDBOX

  return new SignedDataVerifier(certificates, true, environment, env.APPLE_CLIENT_ID)
}

function getVerifier(): SignedDataVerifier {
  if (!verifier) {
    verifier = createVerifier()
  }
  return verifier
}

export interface VerifiedTransaction {
  transactionId: string
  originalTransactionId: string
  productId: string
  purchasedAt: Date
  expiresAt?: Date
  revokedAt?: Date
  environment: string
}

function normalizeTransaction(payload: JWSTransactionDecodedPayload): VerifiedTransaction {
  return {
    transactionId: String(payload.transactionId),
    originalTransactionId: String(payload.originalTransactionId),
    productId: String(payload.productId),
    purchasedAt: new Date(Number(payload.purchaseDate)),
    expiresAt: payload.expiresDate ? new Date(Number(payload.expiresDate)) : undefined,
    revokedAt: payload.revocationDate ? new Date(Number(payload.revocationDate)) : undefined,
    environment: String(payload.environment),
  }
}

function decodePayloadWithoutVerify(signedTransaction: string): VerifiedTransaction {
  const parts = signedTransaction.split('.')
  if (parts.length !== 3) {
    throw new Error('Invalid JWS format')
  }
  const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString())
  return normalizeTransaction(payload as JWSTransactionDecodedPayload)
}

export async function verifyAppleTransaction(signedTransaction: string): Promise<VerifiedTransaction> {
  if (env.APPLE_IAP_SKIP_VERIFY === 'true') {
    return decodePayloadWithoutVerify(signedTransaction)
  }

  const payload = await getVerifier().verifyAndDecodeTransaction(signedTransaction)
  return normalizeTransaction(payload)
}

export interface VerifiedNotification {
  notificationType?: string
  subtype?: string
  transaction?: VerifiedTransaction
}

function decodeNotificationWithoutVerify(signedPayload: string): VerifiedNotification {
  const parts = signedPayload.split('.')
  if (parts.length !== 3) {
    throw new Error('Invalid JWS format')
  }
  const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString()) as ResponseBodyV2DecodedPayload
  const signedTransactionInfo = payload.data?.signedTransactionInfo
  const transaction = signedTransactionInfo ? decodePayloadWithoutVerify(signedTransactionInfo) : undefined
  return {
    notificationType: payload.notificationType,
    subtype: payload.subtype,
    transaction,
  }
}

export async function verifyAppleNotification(signedPayload: string): Promise<VerifiedNotification> {
  if (env.APPLE_IAP_SKIP_VERIFY === 'true') {
    return decodeNotificationWithoutVerify(signedPayload)
  }

  const payload = await getVerifier().verifyAndDecodeNotification(signedPayload)
  const signedTransactionInfo = payload.data?.signedTransactionInfo
  const transaction = signedTransactionInfo
    ? await getVerifier().verifyAndDecodeTransaction(signedTransactionInfo).then(normalizeTransaction)
    : undefined

  return {
    notificationType: payload.notificationType,
    subtype: payload.subtype,
    transaction,
  }
}
