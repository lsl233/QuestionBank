//
//  FilterSheetView.swift
//  QuestionBankApp
//
//  题库筛选 Sheet：集中展示年份、学科、地区/卷型筛选器。
//

import SwiftUI

/// 题库筛选 Sheet：将年份、学科、地区/卷型三个筛选维度集中到一个浮层中。
struct FilterSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PapersViewModel

    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            HStack {
                Text("筛选条件")
                    .font(.serifChinese(.title3, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 32, height: 32)
                        .background(AppTheme.cardBackground)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            // 筛选内容
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    FilterSectionView(
                        title: "年份",
                        options: Paper.years,
                        selection: $viewModel.selectedYear
                    )

                    FilterSectionView(
                        title: "学科",
                        options: Paper.subjects,
                        selection: $viewModel.selectedSubject
                    )

                    FilterSectionView(
                        title: "地区 / 卷型",
                        options: Paper.regions,
                        selection: $viewModel.selectedRegion
                    )
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }

            // 底部操作栏
            HStack(spacing: 12) {
                Button {
                    viewModel.resetFilters()
                } label: {
                    Text("重置")
                        .font(.serifChinese(.subheadline, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.background)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.textTertiary, lineWidth: 1)
                        )
                        .cornerRadius(10)
                }

                Button {
                    dismiss()
                } label: {
                    Text("应用筛选")
                        .font(.serifChinese(.subheadline, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.accent)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppTheme.background)
        }
        .background(AppTheme.background)
    }
}

#Preview {
    FilterSheetView(viewModel: PapersViewModel())
}
