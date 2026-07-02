//
//  NewsSectionView.swift
//  QuestionBankApp
//
//  最新动态区块。
//

import SwiftUI

/// 「最新动态」区块：双语标题行 + 横向滚动卡片列表
struct NewsSectionView: View {
    let news: [NewsItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                BilingualHeaderView(englishTitle: "LATEST NEWS", chineseTitle: "最新动态")

                Spacer()

                Button("查看全部") {
                    // TODO: 跳转到全部动态列表页
                }
                .font(.serifChinese(.subheadline))
                .foregroundColor(.brandCinnabar)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(news) { item in
                        NewsCardView(item: item)
                    }
                }
            }
        }
    }
}
