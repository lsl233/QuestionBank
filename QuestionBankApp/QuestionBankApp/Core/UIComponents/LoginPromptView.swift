//
//  LoginPromptView.swift
//  QuestionBankApp
//
//  未登录时的统一提示视图，提供 Sign in with Apple 入口。
//

import SwiftUI

struct LoginPromptView: View {
    @EnvironmentObject private var authManager: AuthManager
    @State private var errorMessage: String?

    var icon: String = "person.circle"
    var title: String = "登录后查看"
    var onLogin: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(AppTheme.textTertiary)

            Text(title)
                .font(.serifChinese(.headline, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            Button("使用 Apple 登录") {
                Task {
                    do {
                        try await authManager.signInWithApple()
                        onLogin?()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .font(.serifChinese(.subheadline, weight: .semibold))
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(AppTheme.accent)
            .foregroundColor(.white)
            .cornerRadius(8)

            #if DEBUG
            Button("测试账号登录") {
                Task {
                    do {
                        try await authManager.signInWithTestAccount()
                        onLogin?()
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .font(.serifChinese(.subheadline))
            .foregroundColor(AppTheme.textSecondary)
            #endif

            if let errorMessage {
                Text(errorMessage)
                    .font(.serifChinese(.caption))
                    .foregroundColor(AppTheme.error)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }
}

#Preview {
    LoginPromptView()
        .environmentObject(AuthManager())
}
