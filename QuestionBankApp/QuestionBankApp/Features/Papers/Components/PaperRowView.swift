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
            HStack(spacing: 8) {
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
        .cornerRadius(12)
    }

    private var subjectBadge: some View {
        let colors = subjectColors(for: paper.subject)
        return Text(paper.subject)
            .font(.serifChinese(.caption, weight: .semibold))
            .foregroundColor(colors.text)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(colors.background)
            .cornerRadius(6)
    }

    private func subjectColors(for subject: String) -> (background: Color, text: Color) {
        switch subject {
        case "语文":
            return (Color(hex: 0xFCE8E6), Color(hex: 0xC73E1D))
        case "数学", "数学(理)", "数学(文)":
            return (Color(hex: 0xE8F0FE), Color(hex: 0x1A73E8))
        case "英语":
            return (Color(hex: 0xE6F4EA), Color(hex: 0x1E8E3E))
        case "物理":
            return (Color(hex: 0xE3F2FD), Color(hex: 0x1967D2))
        case "化学":
            return (Color(hex: 0xF3E8FD), Color(hex: 0x9334E6))
        case "生物":
            return (Color(hex: 0xE6F5E9), Color(hex: 0x34A853))
        case "历史":
            return (Color(hex: 0xFFF0E6), Color(hex: 0xFA7B17))
        case "地理":
            return (Color(hex: 0xE0F7FA), Color(hex: 0x0097A7))
        default:
            return (AppTheme.secondaryBackground, AppTheme.textSecondary)
        }
    }
}
