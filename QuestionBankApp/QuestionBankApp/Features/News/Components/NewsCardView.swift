//
//  NewsCardView.swift
//  QuestionBankApp
//
//  单张动态卡片组件。
//

import SwiftUI

/// 单张动态卡片：包含标签、日期、标题、描述
struct NewsCardView: View {
    let item: NewsItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.tag)
                    .font(.monoEnglish(.caption2, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brandCinnabar)
                    .cornerRadius(12)

                Spacer()

                Text(item.date)
                    .font(.monoEnglish(.caption))
                    .foregroundColor(.mutedBrown)
            }

            Text(item.title)
                .font(.serifChinese(.subheadline, weight: .semibold))
                .lineLimit(2)
                .foregroundColor(.darkBrown)

            Text(item.description)
                .font(.serifChinese(.caption))
                .foregroundColor(.mutedBrown)
                .lineLimit(2)
        }
        .padding(12)
        .frame(width: 240, height: 120, alignment: .topLeading)
        .background(AppTheme.cardBackground)
//        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(css: "rgba(44, 24, 16, 0.08)"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        // 柔和暖棕色阴影
//        .shadow(color: Color.darkBrown.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}
