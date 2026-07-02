//
//  FilterSheetView.swift
//  QuestionBankApp
//
//  题库筛选 Sheet：集中展示年份、地区、科目筛选器。
//

import SwiftUI

/// 题库筛选 Sheet：将年份、地区、科目三个筛选维度集中到一个浮层中。
struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PapersViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                FilterSectionView(
                    title: "年份",
                    options: Paper.years,
                    selection: $viewModel.selectedYear
                )

                FilterSectionView(
                    title: "地区",
                    options: Paper.regions,
                    selection: $viewModel.selectedRegion
                )

                FilterSectionView(
                    title: "科目",
                    options: Paper.subjects,
                    selection: $viewModel.selectedSubject
                )

                Spacer()

                Button {
                    viewModel.resetFilters()
                } label: {
                    Text("重置筛选")
                        .font(.serifChinese(.subheadline, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 24)
            .background(AppTheme.background)
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accent)
                }
            }
        }
    }
}

#Preview {
    FilterSheetView(viewModel: PapersViewModel())
}
