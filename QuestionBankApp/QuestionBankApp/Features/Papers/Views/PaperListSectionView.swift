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
            HStack(spacing: 8) {
                BilingualHeaderView(englishTitle: "PAPERS", chineseTitle: "试题列表")

                Spacer()

                // 动态显示当前列表中的试卷数量
                Text("\(papers.count) 套")
                    .font(.monoEnglish(.subheadline))
                    .foregroundColor(.mutedBrown)
            }

            LazyVStack(spacing: 12) {
                ForEach(papers) { paper in
                    PaperRowCell(paper: paper)
                }
            }
        }
    }
}
