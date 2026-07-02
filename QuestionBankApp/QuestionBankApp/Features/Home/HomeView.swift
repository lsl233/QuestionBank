//
//  HomeView.swift
//  QuestionBankApp
//
//  应用首页。
//  进入页面后从后端 API 拉取新闻公告；已登录用户同时加载最近收藏。
//

import SwiftUI

/// 应用首页
struct HomeView: View {
    // MARK: - 环境

    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userDataStore: UserDataStore
    @EnvironmentObject private var tabRouter: TabRouter
    @StateObject private var papersViewModel = PapersViewModel()

    // MARK: - 状态

    /// 从后端获取到的新闻公告列表
    @State private var news: [NewsItem] = []

    /// 当前登录用户的收藏试卷（用于首页收藏模块展示）
    @State private var favoritePapers: [Paper] = []

    /// 是否正在加载首页主要数据（新闻）
    @State private var isLoading = true

    /// 是否正在加载收藏模块
    @State private var isLoadingFavorites = false

    /// 加载失败时的错误提示
    @State private var errorMessage: String?

    // MARK: - 计算属性

    /// 根据本地收藏状态实时过滤，取消收藏后立即从首页模块消失
    private var displayedFavorites: [Paper] {
        favoritePapers.filter { userDataStore.isFavorite(paperId: $0.id) }
    }

    /// 只有已登录且存在收藏时才展示收藏模块
    private var shouldShowFavoritesModule: Bool {
        authManager.isLoggedIn && !displayedFavorites.isEmpty
    }

    // MARK: - 视图

    var body: some View {
        NavigationStack {
            Group {
                if let errorMessage {
                    errorView(message: errorMessage)
                } else if isLoading {
                    loadingView
                } else {
                    contentView
                }
            }
            .task {
                await loadData()
            }
        }
    }

    // MARK: - 子视图

    /// 正常首页内容
    private var contentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 24) {
                HeaderView()

                NewsSectionView(news: news)

                LatestQuestionsModule(
                    papers: Array(papersViewModel.papers.prefix(3)),
                    isLoading: papersViewModel.isLoading
                )

                if shouldShowFavoritesModule {
                    FavoritesModule(
                        favoritePapers: displayedFavorites,
                        isLoading: isLoadingFavorites,
                        onViewAll: { tabRouter.selectedTab = .favorites }
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .background(AppTheme.background)
        // 隐藏默认导航栏，由自定义 HeaderView 充当页面标题
        .navigationBarHidden(true)
    }

    /// 加载中视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在加载...")
                .font(.serifChinese(.subheadline))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }

    /// 错误提示视图，带重试按钮
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.error)

            Text("加载失败")
                .font(.serifChinese(.headline, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            Text(message)
                .font(.serifChinese(.subheadline))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)

            Button("重新加载") {
                Task {
                    await loadData()
                }
            }
            .font(.serifChinese(.subheadline, weight: .semibold))
            .padding(.horizontal, 24)
            .padding(.vertical, 8)
            .background(AppTheme.accent)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background)
    }

    // MARK: - 数据加载

    /// 并发加载新闻、最新试卷与收藏数据。
    /// 新闻是首页主要内容，失败时显示全页错误；试卷/收藏失败仅影响对应模块。
    private func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let fetchedNews = APIService.shared.fetchNews()
            async let loadPapers: () = papersViewModel.loadPapers()
            news = try await fetchedNews
            _ = await loadPapers
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false

        // 收藏模块独立加载，不阻塞首页主要内容
        await loadFavorites()
    }

    /// 加载当前用户收藏试卷并同步本地收藏 ID 集合。
    private func loadFavorites() async {
        guard authManager.isLoggedIn else {
            favoritePapers.removeAll()
            return
        }

        isLoadingFavorites = true
        defer { isLoadingFavorites = false }

        do {
            favoritePapers = try await APIService.shared.fetchFavorites()
            await userDataStore.loadFavorites()
        } catch APIError.unauthorized {
            favoritePapers.removeAll()
        } catch {
            NSLog("首页加载收藏失败: \(error.localizedDescription)")
        }
    }
}

// MARK: - 首页收藏模块

/// 首页「我的收藏」模块：横向展示最近收藏，未登录时提供登录入口。
private struct FavoritesModule: View {
    @EnvironmentObject private var authManager: AuthManager

    let favoritePapers: [Paper]
    let isLoading: Bool
    let onViewAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MY FAVORITES")
                        .font(.monoEnglish(.caption2, weight: .bold))
                        .foregroundColor(.brandCinnabar)

                    Text("我的收藏")
                        .font(.serifChinese(.headline, weight: .semibold))
                        .foregroundColor(.darkBrown)
                }

                Spacer()

                if authManager.isLoggedIn && !favoritePapers.isEmpty {
                    Button("查看全部") {
                        onViewAll()
                    }
                    .font(.serifChinese(.subheadline))
                    .foregroundColor(.brandCinnabar)
                }
            }

            if !authManager.isLoggedIn {
                loginPromptCard
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if favoritePapers.isEmpty {
                emptyCard
            } else {
                favoritesScrollView
            }
        }
    }

    private var favoritesScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(favoritePapers.prefix(5)) { paper in
                    CompactPaperCard(paper: paper)
                }
            }
        }
    }

    private var loginPromptCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.textTertiary)

            Text("登录后查看收藏")
                .font(.serifChinese(.subheadline))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
    }

    private var emptyCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "star")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.textTertiary)

            Text("暂无收藏试卷")
                .font(.serifChinese(.subheadline))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - 紧凑试卷卡片

/// 首页横向列表中使用的紧凑试卷卡片：内容 + 收藏星标 + 进入详情。
private struct CompactPaperCard: View {
    let paper: Paper

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(destination: PaperDetailView(paper: paper)) {
                cardContent
            }
            // 使用 PlainButtonStyle 避免 NavigationLink 默认的蓝色高亮/背景
            .buttonStyle(PlainButtonStyle())

            FavoriteStarButton(paper: paper)
                .padding(.top, 8)
                .padding(.trailing, 8)
        }
        .frame(width: 200, height: 120)
        .background(AppTheme.cardBackground)
        .border(Color(css: "rgba(44, 24, 16, 0.08)"), width: 1)
        .cornerRadius(12)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(paper.subject)
                    .font(.serifChinese(.caption, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.brandCinnabar)
                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 2, height: 3), style: .circular))

                Text(paper.year)
                    .font(.monoEnglish(.caption, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)

                Spacer()
            }

            Text(paper.displayTitle)
                .font(.serifChinese(.subheadline, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer()

            Text(paper.region)
                .font(.serifChinese(.caption))
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(12)
        .frame(width: 200, height: 120, alignment: .leading)
    }
}

// MARK: - 最新试题模块

/// 首页「最新试题」模块：样式与题库列表一致，展示最近 3 套试题，不显示收藏按钮，显示创建时间。
private struct LatestQuestionsModule: View {
    let papers: [Paper]
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LATEST QUESTIONS")
                        .font(.monoEnglish(.caption2, weight: .bold))
                        .foregroundColor(.brandCinnabar)

                    Text("最新试题")
                        .font(.serifChinese(.headline, weight: .semibold))
                        .foregroundColor(.darkBrown)
                }

                Spacer()

                if !papers.isEmpty {
                    Text("\(papers.count) 套")
                        .font(.monoEnglish(.subheadline))
                        .foregroundColor(.mutedBrown)
                }
            }

            if isLoading && papers.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            } else if papers.isEmpty {
                emptyCard
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(papers) { paper in
                        NavigationLink(destination: PaperDetailView(paper: paper)) {
                            LatestQuestionRow(paper: paper)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    private var emptyCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 32))
                .foregroundColor(AppTheme.textTertiary)

            Text("暂无试卷")
                .font(.serifChinese(.subheadline))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
    }
}

// MARK: - 最新试题行

/// 首页最新试题列表中的单行：与题库卡片布局一致，无收藏按钮，显示创建时间。
private struct LatestQuestionRow: View {
    let paper: Paper

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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

            Text(paper.displayTitle)
                .font(.serifChinese(.headline, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)

            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 10, weight: .medium))

                Text(formattedCreatedAt(paper.createdAt))
                    .font(.monoEnglish(.caption))
            }
            .foregroundColor(AppTheme.textTertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .border(Color(css: "rgba(44, 24, 16, 0.08)"), width: 1)
        .background(AppTheme.cardBackground)
        .cornerRadius(6)
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

    private func formattedCreatedAt(_ isoString: String?) -> String {
        guard let isoString = isoString, !isoString.isEmpty else { return "--" }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = isoFormatter.date(from: isoString) else { return isoString }
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy.MM.dd"
        return displayFormatter.string(from: date)
    }
}

#Preview {
    HomeView()
        .environmentObject(AuthManager())
        .environmentObject(UserDataStore())
        .environmentObject(TabRouter())
}
