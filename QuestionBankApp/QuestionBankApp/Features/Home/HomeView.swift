//
//  HomeView.swift
//  QuestionBankApp
//
//  应用首页。
//  进入页面后从后端 API 拉取试卷列表和新闻公告。
//

import SwiftUI

/// 应用首页
struct HomeView: View {
    // MARK: - 状态

    /// 搜索框输入文本，实时过滤试卷列表
    @State private var searchText = ""

    /// 当前选中的年份筛选条件，默认"全部"
    @State private var selectedYear = Paper.years[0]

    /// 当前选中的地区/卷别筛选条件，默认"全部"
    @State private var selectedRegion = Paper.regions[0]

    /// 当前选中的科目筛选条件，默认"全部"
    @State private var selectedSubject = Paper.subjects[0]

    /// 从后端获取到的试卷列表
    @State private var papers: [Paper] = []

    /// 从后端获取到的新闻公告列表
    @State private var news: [NewsItem] = []

    /// 是否正在加载数据（用于显示 loading）
    @State private var isLoading = true

    /// 加载失败时的错误提示
    @State private var errorMessage: String?

    // MARK: - 计算属性

    /// 根据搜索文本与三个筛选条件计算出的当前展示试卷列表
    private var filteredPapers: [Paper] {
        papers.filter { paper in
            let title = paper.title
            let matchesSearch = searchText.isEmpty || title.contains(searchText)
            let matchesYear = selectedYear == Paper.years[0] || paper.year == selectedYear
            let matchesRegion = selectedRegion == Paper.regions[0] || paper.region == selectedRegion
            let matchesSubject = selectedSubject == Paper.subjects[0] || paper.subject == selectedSubject
            return matchesSearch && matchesYear && matchesRegion && matchesSubject
        }
    }

    // MARK: - 视图

    var body: some View {
        NavigationStack {
            Group {
                // 如果有错误，优先显示错误提示
                if let errorMessage {
                    errorView(message: errorMessage)
                }
                // 首次加载中显示进度指示器
                else if isLoading {
                    loadingView
                }
                // 正常情况显示首页内容
                else {
                    contentView
                }
            }
            // 视图出现时并发拉取试卷和新闻数据
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

//                HeroCardView()

//                SearchBarView(searchText: $searchText)

                // 筛选区：年份 / 地区 / 科目
//                FilterSectionView(
//                    title: "年份",
//                    options: Paper.years,
//                    selection: $selectedYear
//                )
//
//                FilterSectionView(
//                    title: "地区",
//                    options: Paper.regions,
//                    selection: $selectedRegion
//                )
//
//                FilterSectionView(
//                    title: "科目",
//                    options: Paper.subjects,
//                    selection: $selectedSubject
//                )

                NewsSectionView(news: news)

                PaperListSectionView(papers: filteredPapers)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        // 使用暖白纸张背景
        .background(AppTheme.background)
        // 隐藏默认导航栏，由自定义 HeaderView 充当页面标题
        .navigationBarHidden(true)
    }

    /// 加载中视图
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在加载试卷...")
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
                // 点击后再次触发加载
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

    /// 并发加载试卷列表和新闻公告。
    /// 使用 async let 让两个请求同时发起，缩短等待时间。
    private func loadData() async {
        // 开始加载前清空错误、显示 loading
        isLoading = true
        errorMessage = nil

        do {
            // 同时发起两个请求
            async let fetchedPapers = APIService.shared.fetchPapers()
            async let fetchedNews = APIService.shared.fetchNews()

            // 等待两个请求都完成
            papers = try await fetchedPapers
            news = try await fetchedNews
        } catch let error as APIError {
            // 如果是我们定义的网络错误，使用本地化描述
            errorMessage = error.localizedDescription
        } catch {
            // 其他错误（如网络断开）显示原始信息
            errorMessage = error.localizedDescription
        }

        // 无论成功失败，都结束 loading
        isLoading = false
    }
}

#Preview {
    HomeView()
}
