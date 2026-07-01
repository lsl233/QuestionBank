import { SignedDataVerifier, Environment } from '@apple/app-store-server-library';
import fs from 'node:fs';
import path from 'node:path';
import { env } from '../config/env.js';
let verifier = null;
function createVerifier() {
    const certsDir = path.resolve(env.APPLE_ROOT_CA_DIR);
    const certFiles = fs
        .readdirSync(certsDir)
        .filter((name) => /\.(cer|crt|der|pem)$/i.test(name))
        .map((name) => path.join(certsDir, name));
    if (certFiles.length === 0 && env.APPLE_IAP_SKIP_VERIFY !== 'true') {
        throw new Error(`No Apple root certificates found in ${certsDir}. Download them from https://www.apple.com/certificateauthority/ or set APPLE_IAP_SKIP_VERIFY=true for development.`);
    }
    const certificates = certFiles.map((file) => fs.readFileSync(file));
    const environment = env.APPLE_IAP_ENV === 'production' ? Environment.PRODUCTION : Environment.SANDBOX;
    return new SignedDataVerifier(certificates, true, environment, env.APPLE_CLIENT_ID);
}
function getVerifier() {
    if (!verifier) {
        verifier = createVerifier();
    }
    return verifier;
}
function normalizeTransaction(payload) {
    return {
        transactionId: String(payload.transactionId),
        originalTransactionId: String(payload.originalTransactionId),
        productId: String(payload.productId),
        purchasedAt: new Date(Number(payload.purchaseDate)),
        expiresAt: payload.expiresDate ? new Date(Number(payload.expiresDate)) : undefined,
        revokedAt: payload.revocationDate ? new Date(Number(payload.revocationDate)) : undefined,
        environment: String(payload.environment),
    };
}
function decodePayloadWithoutVerify(signedTransaction) {
    const parts = signedTransaction.split('.');
    if (parts.length !== 3) {
        throw new Error('Invalid JWS format');
    }
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString());
    return normalizeTransaction(payload);
}
export async function verifyAppleTransaction(signedTransaction) {
    if (env.APPLE_IAP_SKIP_VERIFY === 'true') {
        return decodePayloadWithoutVerify(signedTransaction);
    }
    const payload = await getVerifier().verifyAndDecodeTransaction(signedTransaction);
    return normalizeTransaction(payload);
}
function decodeNotificationWithoutVerify(signedPayload) {
    const parts = signedPayload.split('.');
    if (parts.length !== 3) {
        throw new Error('Invalid JWS format');
    }
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString());
    const signedTransactionInfo = payload.data?.signedTransactionInfo;
    const transaction = signedTransactionInfo ? decodePayloadWithoutVerify(signedTransactionInfo) : undefined;
    return {
        notificationType: payload.notificationType,
        subtype: payload.subtype,
        transaction,
    };
}
export async function verifyAppleNotification(signedPayload) {
    if (env.APPLE_IAP_SKIP_VERIFY === 'true') {
        return decodeNotificationWithoutVerify(signedPayload);
    }
    const payload = await getVerifier().verifyAndDecodeNotification(signedPayload);
    const signedTransactionInfo = payload.data?.signedTransactionInfo;
    const transaction = signedTransactionInfo
        ? await getVerifier().verifyAndDecodeTransaction(signedTransactionInfo).then(normalizeTransaction)
        : undefined;
    return {
        notificationType: payload.notificationType,
        subtype: payload.subtype,
        transaction,
    };
}
