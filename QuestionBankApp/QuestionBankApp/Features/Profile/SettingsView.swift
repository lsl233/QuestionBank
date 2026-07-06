//
//  SettingsView.swift
//  QuestionBankApp
//
//  设置菜单：账号相关的退出登录与删除账号入口。
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userDataStore: UserDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var showSignOutConfirmation = false
    @State private var showDeleteConfirmation = false
    @State private var showDeleteErrorAlert = false
    @State private var deleteErrorMessage: String?
    @State private var isDeleting = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 12) {
                if authManager.isLoggedIn {
                    signOutRow
                    deleteAccountRow
                } else {
                    Text("当前未登录")
                        .font(.serifChinese(.subheadline))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .background(AppTheme.background.ignoresSafeArea())
        .navigationTitle("设置")
        .navigationBarTitleDisplayMode(.inline)
        .alert("退出登录", isPresented: $showSignOutConfirmation) {
            Button("取消", role: .cancel) {}
            Button("退出", role: .destructive) {
                performSignOut()
            }
        } message: {
            Text("退出后需要重新登录才能查看会员状态和下载记录。")
        }
        .alert("删除账号", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                Task { await performDeleteAccount() }
            }
        } message: {
            Text("此操作不可恢复。删除后，您的收藏、下载记录、学习记录、勘误反馈和会员状态将全部清除。")
        }
        .alert("删除失败", isPresented: $showDeleteErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage ?? "请检查网络后重试")
        }
    }

    private var signOutRow: some View {
        Button {
            showSignOutConfirmation = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "arrow.right.square")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 28)

                Text("退出登录")
                    .font(.serifChinese(.headline, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(16)
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var deleteAccountRow: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "trash")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(AppTheme.error)
                    .frame(width: 28)

                Text("删除账号")
                    .font(.serifChinese(.headline, weight: .semibold))
                    .foregroundColor(AppTheme.error)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppTheme.textTertiary)
            }
            .padding(16)
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDeleting)
    }

    private func performSignOut() {
        authManager.signOut()
        userDataStore.clear()
        dismiss()
    }

    private func performDeleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await APIService.shared.deleteAccount()
            await completeLocalCleanup()
        } catch APIError.unauthorized {
            await completeLocalCleanup()
        } catch let error as APIError {
            deleteErrorMessage = error.localizedDescription
            showDeleteErrorAlert = true
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteErrorAlert = true
        }
    }

    private func completeLocalCleanup() async {
        authManager.signOut()
        userDataStore.clear()
        dismiss()
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthManager())
            .environmentObject(UserDataStore())
    }
}
