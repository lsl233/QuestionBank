//
//  SearchBarView.swift
//  QuestionBankApp
//
//  通用搜索框组件。
//

import SwiftUI

/// 首页搜索框，输入内容会实时同步到调用方的搜索状态
struct SearchBarView: View {
    @Binding var searchText: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppTheme.textTertiary)

            TextField("搜索试卷", text: $searchText)
                .font(.serifChinese(.subheadline))
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(AppTheme.cardBackground)
        .cornerRadius(10)
    }
}
