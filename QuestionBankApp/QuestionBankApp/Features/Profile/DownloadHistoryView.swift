//
//  DownloadHistoryView.swift
//  QuestionBankApp
//
//  下载历史列表。
//

import SwiftUI

struct DownloadHistoryView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var downloads: [DownloadItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            LoginGuardView(
                icon: "arrow.down.circle",
                title: "登录后查看下载历史",
                onLogin: { Task { await load() } }
            ) {
                AsyncListContainerView(
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    items: downloads,
                    emptyIcon: "arrow.down.circle",
                    emptyText: "暂无下载记录",
                    onRetry: { Task { await load() } }
                ) { item in
                    recordRow(item)
                }

            }
        }
        .navigationTitle("下载历史")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
        .padding(.horizontal, 16)
        .background(AppTheme.background.ignoresSafeArea())
        .toolbar(.hidden, for: .tabBar)

    }

    private func recordRow(_ item: DownloadItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.paperTitle)
                    .font(.serifChinese(.subheadline, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)

                Text(item.createdAt)
                    .font(.monoEnglish(.caption))
                    .foregroundColor(AppTheme.textTertiary)
            }

            Spacer()
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await APIService.shared.authenticatedRequest(path: "/downloads")
            let response = try JSONDecoder().decode(DownloadsResponse.self, from: data)
            downloads = response.downloads.map {
                DownloadItem(
                    id: $0.id,
                    paperTitle: $0.paper?.displayTitle ?? "未知试卷",
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

private struct DownloadItem: Identifiable {
    let id: String
    let paperTitle: String
    let createdAt: String
}

private struct DownloadsResponse: Decodable {
    struct Download: Decodable {
        let id: String
        let paper: Paper?
        let createdAt: String
    }
    let downloads: [Download]
}
