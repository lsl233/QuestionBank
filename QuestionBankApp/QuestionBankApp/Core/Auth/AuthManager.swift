//
//  AuthManager.swift
//  QuestionBankApp
//
//  管理 Sign in with Apple 登录态。
//

import SwiftUI
import AuthenticationServices
import Combine

/// 登录状态管理器
@MainActor
final class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var userName: String?

    init() {
        isLoggedIn = KeychainTokenStore.load() != nil
    }

    /// 使用 Apple ID 登录并换取后端 JWT
    func signInWithApple() async throws {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]

        let credential = try await withCheckedThrowingContinuation { continuation in
            let delegate = SignInWithAppleDelegate(continuation: continuation)
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = delegate
            controller.presentationContextProvider = delegate
            controller.performRequests()

            // 保持 delegate 存活直到回调完成
            objc_setAssociatedObject(controller, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN)
        }

        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.missingIdentityToken
        }

        let token = try await APIService.shared.signInWithApple(
            identityToken: tokenString,
            email: credential.email,
            givenName: credential.fullName?.givenName,
            familyName: credential.fullName?.familyName
        )
        KeychainTokenStore.save(token: token)
        isLoggedIn = true
    }

    #if DEBUG
    /// 测试环境一键登录，仅 DEBUG 构建可用
    func signInWithTestAccount() async throws {
        let token = try await APIService.shared.testLogin()
        KeychainTokenStore.save(token: token)
        isLoggedIn = true
    }
    #endif

    func signOut() {
        KeychainTokenStore.delete()
        isLoggedIn = false
        userName = nil
    }

    var token: String? {
        KeychainTokenStore.load()
    }
}

enum AuthError: Error, LocalizedError {
    case missingIdentityToken
    case authorizationFailed(Error?)

    var errorDescription: String? {
        switch self {
        case .missingIdentityToken:
            return "无法获取 Apple 登录凭证"
        case .authorizationFailed(let error):
            return error?.localizedDescription ?? "Apple 登录失败"
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

private final class SignInWithAppleDelegate: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    let continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>

    init(continuation: CheckedContinuation<ASAuthorizationAppleIDCredential, Error>) {
        self.continuation = continuation
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation.resume(throwing: AuthError.authorizationFailed(nil))
            return
        }
        continuation.resume(returning: credential)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation.resume(throwing: AuthError.authorizationFailed(error))
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Sign in with Apple 弹窗时一定存在 UIWindowScene
        let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first!
        return windowScene.windows.first ?? UIWindow(windowScene: windowScene)
    }
}
