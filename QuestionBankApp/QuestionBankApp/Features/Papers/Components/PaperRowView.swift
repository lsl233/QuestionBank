//
//  PaperRowView.swift
//  QuestionBankApp
//
//  单条试卷行组件。
//

import SwiftUI

/// 单条试卷行：朱砂红 PDF 图标 + 标题/副标题 + 右侧箭头
struct PaperRowView: View {
    let paper: Paper

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.brandCinnabar.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: "doc.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.brandCinnabar)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(paper.title)
                    .font(.serifChinese(.subheadline, weight: .semibold))
                    .foregroundColor(.darkBrown)
                    .lineLimit(1)

                Text("高考真题 · PDF")
                    .font(.monoEnglish(.caption))
                    .foregroundColor(.mutedBrown)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.lightBrown)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
    }
}
