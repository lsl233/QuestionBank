//
//  FavoritesView.swift
//  QuestionBankApp
//
//  收藏 Tab：展示当前用户收藏的试卷。
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userDataStore: UserDataStore

    @State private var favoritePapers: [Paper] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    /// 收藏列表，根据本地 favoriteIDs 实时过滤，移除收藏后立即消失
    private var displayedFavorites: [Paper] {
        favoritePapers.filter { userDataStore.isFavorite(paperId: $0.id) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                BilingualHeaderView(
                    englishTitle: "FAVORITES",
                    chineseTitle: "我的收藏",
                    style: .home
                )
                LoginGuardView(
                    icon: "star.circle",
                    title: "登录后查看收藏",
                    onLogin: { Task { await loadFavorites() } }
                ) {
                    AsyncListContainerView(
                        isLoading: isLoading,
                        errorMessage: errorMessage,
                        items: displayedFavorites,
                        emptyIcon: "star",
                        emptyText: "暂无收藏试卷",
                        onRetry: { Task { await loadFavorites() } }
                    ) { paper in
                        PaperRowCell(paper: paper)
                    }
                    // .navigationTitle("Favorites")
                    // .navigationBarTitleDisplayMode(.large)
                    .task {
                        await loadFavorites()
                    }
                }
                
            }
            .padding(.horizontal, 16)
            .background(AppTheme.background)
        }

    }

    private func loadFavorites() async {
        guard authManager.isLoggedIn else { return }
        isLoading = true
        errorMessage = nil
        do {
            favoritePapers = try await APIService.shared.fetchFavorites()
            await userDataStore.loadFavorites()
        } catch APIError.unauthorized {
            errorMessage = "登录已过期"
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
