//
//  FilterSectionView.swift
//  QuestionBankApp
//
//  通用单行胶囊筛选组件。
//

import SwiftUI

/// 通用单行筛选组件：标题 + 横向滚动的胶囊按钮
/// - 可用于年份、地区、科目等任意一组互斥选项
struct FilterSectionView: View {
    let title: String
    let options: [String]
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.serifChinese(.subheadline))
                .foregroundColor(AppTheme.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(options, id: \.self) { option in
                        Button {
                            selection = option
                        } label: {
                            Text(option)
                                .font(.serifChinese(.subheadline, weight: selection == option ? .semibold : .regular))
                                .foregroundColor(selection == option ? .white : AppTheme.textPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(selection == option ? Color.brandCinnabar : AppTheme.cardBackground)
                                .cornerRadius(16)
                        }
                    }
                }
            }
        }
    }
}
