//
//  CorrectionListView.swift
//  QuestionBankApp
//
//  错误反馈（勘误）列表。
//

import SwiftUI

struct CorrectionListView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var corrections: [CorrectionItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            LoginGuardView(
                icon: "exclamationmark.circle",
                title: "登录后查看错误反馈",
                onLogin: { Task { await load() } }
            ) {
                AsyncListContainerView(
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    items: corrections,
                    emptyIcon: "exclamationmark.circle",
                    emptyText: "暂无反馈记录",
                    onRetry: { Task { await load() } }
                ) { item in
                    correctionRow(item)
                }

            }
            .padding(.horizontal, 16)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("错误反馈")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await load()
            }
            .toolbar(.hidden, for: .tabBar)
        }

    }

    private func correctionRow(_ item: CorrectionItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.paperTitle)
                    .font(.serifChinese(.subheadline, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text(item.statusText)
                    .font(.monoEnglish(.caption2, weight: .medium))
                    .foregroundColor(statusColor(item.status))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor(item.status).opacity(0.12))
                    .cornerRadius(4)
            }

            Text(item.content)
                .font(.serifChinese(.body))
                .foregroundColor(AppTheme.textSecondary)
                .lineLimit(3)

            Text(item.createdAt)
                .font(.monoEnglish(.caption))
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
    }

    private func statusColor(_ status: String) -> Color {
        switch status {
        case "resolved":
            return Color(hex: 0x34A853)
        case "ignored":
            return AppTheme.textTertiary
        default:
            return AppTheme.accent
        }
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await APIService.shared.authenticatedRequest(path: "/corrections")
            let response = try JSONDecoder().decode(CorrectionsResponse.self, from: data)
            corrections = response.corrections.map {
                CorrectionItem(
                    id: $0.id,
                    paperTitle: $0.paper?.displayTitle ?? "未知试卷",
                    content: $0.content,
                    status: $0.status,
                    createdAt: formatDate($0.createdAt)
                )
            }
        } catch APIError.unauthorized {
            errorMessage = "登录已过期"
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func formatDate(_ string: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: string) else { return string }
        let output = DateFormatter()
        output.dateStyle = .medium
        output.timeStyle = .none
        return output.string(from: date)
    }
}

private struct CorrectionItem: Identifiable {
    let id: String
    let paperTitle: String
    let content: String
    let status: String
    let createdAt: String

    var statusText: String {
        switch status {
        case "resolved": return "已处理"
        case "ignored": return "已忽略"
        default: return "待处理"
        }
    }
}

private struct CorrectionsResponse: Decodable {
    struct Correction: Decodable {
        let id: String
        let paper: Paper?
        let content: String
        let status: String
        let createdAt: String
        let updatedAt: String
    }
    let corrections: [Correction]
}
