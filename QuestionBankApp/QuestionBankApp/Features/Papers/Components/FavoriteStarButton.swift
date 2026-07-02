//
//  FavoriteStarButton.swift
//  QuestionBankApp
//
//  收藏星标按钮。
//

import SwiftUI

struct FavoriteStarButton: View {
    let paper: Paper
    @EnvironmentObject private var userDataStore: UserDataStore

    var body: some View {
        Button {
            Task {
                await userDataStore.toggleFavorite(paper: paper)
            }
        } label: {
            Image(systemName: userDataStore.isFavorite(paperId: paper.id) ? "star.fill" : "star")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(userDataStore.isFavorite(paperId: paper.id) ? AppTheme.accent : AppTheme.textTertiary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }
}
