//
//  StoreKitPurchaseService.swift
//  QuestionBankApp
//
//  StoreKit 购买服务：请求商品、发起购买、校验交易并上报服务端。
//

import StoreKit

enum MembershipPurchaseError: LocalizedError {
    case productNotFound
    case userCancelled
    case pending
    case failedVerification
    case serverVerifyFailed(String)
    case unknown

    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "未找到对应会员商品，请稍后再试"
        case .userCancelled:
            return "已取消支付"
        case .pending:
            return "支付正在等待确认，请稍后查看"
        case .failedVerification:
            return "交易校验失败，请联系客服"
        case .serverVerifyFailed(let message):
            return message
        case .unknown:
            return "支付过程出现未知错误"
        }
    }
}

/// StoreKit 会员购买服务
@MainActor
final class StoreKitPurchaseService {
    static let shared = StoreKitPurchaseService()

    private init() {}

    /// 为指定计划发起应用内购买，购买成功后会将 JWS 提交给服务端激活会员。
    func purchase(plan: MembershipPlan) async throws {
        NSLog("[StoreKit] 请求商品: \(plan.appleProductId)")
        let products = try await Product.products(for: [plan.appleProductId])
        NSLog("[StoreKit] 返回商品数量: \(products.count)")
        guard let product = products.first else {
            throw MembershipPurchaseError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            guard let jws = String(data: transaction.jsonRepresentation, encoding: .utf8) else {
                throw MembershipPurchaseError.failedVerification
            }
            try await APIService.shared.verifyApplePurchase(jws: jws)
            await transaction.finish()

        case .userCancelled:
            throw MembershipPurchaseError.userCancelled

        case .pending:
            throw MembershipPurchaseError.pending

        @unknown default:
            throw MembershipPurchaseError.unknown
        }
    }

    /// 校验 StoreKit 返回的 VerificationResult
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            NSLog("StoreKit 交易校验失败: \(error.localizedDescription)")
            throw MembershipPurchaseError.failedVerification
        case .verified(let transaction):
            return transaction
        }
    }
}
