//
//  PaperRowView.swift
//  QuestionBankApp
//
//  单条试卷卡片组件（仅内容，不带收藏星标）。
//

import SwiftUI

/// 单条试卷卡片：科目标签 + 年份/卷别 + 标题 + 查看次数
struct PaperRowView: View {
    let paper: Paper

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 顶部：科目标签 + 年份 + 卷别
            HStack(spacing: 6) {
                subjectBadge

                Text(paper.year)
                    .font(.monoEnglish(.caption, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)

                Text("·")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppTheme.textTertiary)

                Text(paper.region)
                    .font(.serifChinese(.caption, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }

            // 中部：标题
            Text(paper.displayTitle)
                .font(.serifChinese(.headline, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)

            // 底部：查看次数
            HStack(spacing: 4) {
                Text("\(paper.viewCount) 次查看")
                    .font(.monoEnglish(.caption))
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color(css: "rgba(44, 24, 16, 0.08)"), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var subjectBadge: some View {
        let colors = subjectColors(for: paper.subject)
        return Text(paper.subject)
            .font(.serifChinese(.caption, weight: .semibold))
            .foregroundColor(colors.text)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(colors.background)
            .clipShape(RoundedRectangle(cornerSize: CGSize(width: 2, height: 3), style: .circular))
    }

    private func subjectColors(for subject: String) -> (background: Color, text: Color) {
        let badgeText = Color(hex: 0xF5F1E8)
        switch subject {
        case "语文":
            return (Color(hex: 0xC73E1D), badgeText)
        case "数学", "数学(理)":
            return (Color(hex: 0x3A6080), badgeText)
        case "数学(文)":
            return (Color(hex: 0x4E6B8A), badgeText)
        case "英语":
            return (Color(hex: 0x5C7A4E), badgeText)
        case "物理":
            return (Color(hex: 0x3A6080), badgeText)
        case "化学":
            return (Color(hex: 0x7B4E8A), badgeText)
        case "生物":
            return (Color(hex: 0x4E8A6B), badgeText)
        case "历史":
            return (Color(hex: 0x8A6B4E), badgeText)
        case "地理":
            return (Color(hex: 0x4E6B8A), badgeText)
        case "政治":
            return (Color(hex: 0x8A4E4E), badgeText)
        default:
            return (AppTheme.secondaryBackground, badgeText)
        }
    }
}
