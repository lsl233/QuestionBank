//
//  PaperRowCell.swift
//  QuestionBankApp
//
//  可复用试卷行单元：内容卡片 + 收藏星标 + 进入详情导航。
//

import SwiftUI

/// 试卷列表中的可点击行单元。
/// 包含 `PaperRowView` 内容卡片、右上角收藏星标，并包裹 `NavigationLink` 进入 `PaperDetailView`。
struct PaperRowCell: View {
    let paper: Paper

    var body: some View {
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

#Preview {
    PaperRowCell(paper: Paper(
        id: "preview",
        year: "2024",
        examType: "高考",
        region: "全国甲卷",
        subject: "数学",
        stream: "理科",
        note: "",
        fileName: "preview.pdf",
        title: "2024 年全国甲卷数学（理）试题",
        viewCount: 128,
        createdAt: "2024-06-07T09:00:00.000Z"
    ))
    .padding()
    .background(AppTheme.background)
    .environmentObject(UserDataStore())
}
