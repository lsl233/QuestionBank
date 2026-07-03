//
//  AsyncListContainerView.swift
//  QuestionBankApp
//
//  异步列表状态容器：统一处理 loading / error / empty / list 四种状态。
//

import SwiftUI

struct AsyncListContainerView<Item: Identifiable, Row: View>: View {
    let isLoading: Bool
    let errorMessage: String?
    let items: [Item]
    let emptyIcon: String
    let emptyText: String
    let onRetry: () -> Void
    @ViewBuilder let row: (Item) -> Row

    var body: some View {
        Group {
            if isLoading {
                loadingView
            } else if let errorMessage {
                errorView(message: errorMessage)
            } else if items.isEmpty {
                emptyView
            } else {
                listView
            }
        }
    }

    private var listView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(items) { item in
                    row(item)
                }
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在加载...")
                .font(.serifChinese(.subheadline))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: emptyIcon)
                .font(.system(size: 48))
                .foregroundColor(AppTheme.textTertiary)
            Text(emptyText)
                .font(.serifChinese(.subheadline))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.error)
            Text("加载失败")
                .font(.serifChinese(.headline, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            Text(message)
                .font(.serifChinese(.subheadline))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            Button("重新加载") {
                onRetry()
            }
            .font(.serifChinese(.subheadline, weight: .semibold))
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(AppTheme.accent)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
