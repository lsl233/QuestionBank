//
//  StudyRecordView.swift
//  QuestionBankApp
//
//  学习记录列表。
//

import SwiftUI

struct StudyRecordView: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var records: [StudyRecordItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        LoginGuardView(
            icon: "clock",
            title: "登录后查看学习记录",
            onLogin: { Task { await load() } }
        ) {
            AsyncListContainerView(
                isLoading: isLoading,
                errorMessage: errorMessage,
                items: records,
                emptyIcon: "clock",
                emptyText: "暂无学习记录",
                onRetry: { Task { await load() } }
            ) { item in
                recordRow(item)
            }
            .navigationTitle("学习记录")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await load()
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }

    private func recordRow(_ item: StudyRecordItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(item.paperTitle)
                    .font(.serifChinese(.subheadline, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)

                Text(item.viewedAt)
                    .font(.monoEnglish(.caption))
                    .foregroundColor(AppTheme.textTertiary)
            }

            Spacer()

            Text("\(item.durationSec)s")
                .font(.monoEnglish(.caption, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
    }

    private func load() async {
        isLoading = true
        errorMessage = nil
        do {
            let data = try await APIService.shared.authenticatedRequest(path: "/study-records")
            let response = try JSONDecoder().decode(StudyRecordsResponse.self, from: data)
            records = response.records.map {
                StudyRecordItem(
                    id: $0.id,
                    paperTitle: $0.paper?.displayTitle ?? "未知试卷",
                    viewedAt: formatDate($0.viewedAt),
                    durationSec: $0.durationSec
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

private struct StudyRecordItem: Identifiable {
    let id: String
    let paperTitle: String
    let viewedAt: String
    let durationSec: Int
}

private struct StudyRecordsResponse: Decodable {
    struct Record: Decodable {
        let id: String
        let paper: Paper?
        let viewedAt: String
        let durationSec: Int
    }
    let records: [Record]
}
