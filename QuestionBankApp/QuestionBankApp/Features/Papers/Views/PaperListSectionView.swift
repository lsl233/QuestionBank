//
//  PaperListSectionView.swift
//  QuestionBankApp
//
//  试题列表区块。
//

import SwiftUI

/// 「试题列表」区块：双语标题行 + 试卷卡片列表
/// 试卷总数根据传入的 papers 数组动态显示
struct PaperListSectionView: View {
    let papers: [Paper]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("PAPERS")
                        .font(.monoEnglish(.caption2, weight: .bold))
                        .foregroundColor(.brandCinnabar)

                    Text("试题列表")
                        .font(.serifChinese(.headline, weight: .semibold))
                        .foregroundColor(.darkBrown)
                }

                Spacer()

                // 动态显示当前列表中的试卷数量
                Text("\(papers.count) 套")
                    .font(.monoEnglish(.subheadline))
                    .foregroundColor(.mutedBrown)
            }

            LazyVStack(spacing: 12) {
                ForEach(papers) { paper in
                    ZStack(alignment: .topTrailing) {
                        NavigationLink(destination: PaperDetailView(paper: paper)) {
                            PaperRowView(paper: paper)
                        }
                        // 使用 PlainButtonStyle 避免 NavigationLink 默认的蓝色高亮/背景
                        .buttonStyle(PlainButtonStyle())

                        FavoriteStarButton(paper: paper)
                            .padding(.top, 8)
                            .padding(.trailing, 8)
                    }
                }
            }
        }
    }
}
