//
//  LoginGuardView.swift
//  QuestionBankApp
//
//  登录守卫：未登录时显示统一登录提示，已登录时渲染内容。
//

import SwiftUI

struct LoginGuardView<Content: View>: View {
    @EnvironmentObject private var authManager: AuthManager

    var icon: String = "person.circle"
    var title: String = "登录后查看"
    var onLogin: (() -> Void)?
    @ViewBuilder let content: () -> Content

    var body: some View {
        Group {
            if authManager.isLoggedIn {
                content()
            } else {
                LoginPromptView(icon: icon, title: title, onLogin: onLogin)
            }
        }
    }
}
