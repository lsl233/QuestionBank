//
//  HeaderView.swift
//  QuestionBankApp
//
//  首页顶部标题区。
//

import SwiftUI

/// 首页顶部标题：英文标识 + 大标题 + 副标题
struct HeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("GAOKAO")
                .font(.monoEnglish(.caption, weight: .bold))
                .tracking(3)
                .foregroundColor(.brandCinnabar)

            Text("高考真题")
                .font(.serifChinese(.largeTitle, weight: .black))
                .foregroundColor(.darkBrown)

            Text("历年真题 · 速查速练")
                .font(.serifChinese(.subheadline))
                .foregroundColor(.mutedBrown)

            Divider()
                .background(AppTheme.divider)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
