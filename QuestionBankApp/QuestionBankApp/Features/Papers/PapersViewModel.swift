//
//  PapersViewModel.swift
//  QuestionBankApp
//
//  题库 Tab 的浏览状态：搜索、筛选、试卷列表加载与本地过滤。
//

import SwiftUI
import Combine

/// 题库浏览视图模型。
/// 承载原本位于 `HomeView` 中的搜索、筛选、试卷加载与过滤逻辑，
/// 使 `PapersView` 专注于视图组合。
@MainActor
final class PapersViewModel: ObservableObject {
    /// 搜索框输入文本，实时过滤试卷列表
    @Published var searchText = ""

    /// 当前选中的年份筛选条件，默认"全部"
    @Published var selectedYear = Paper.years[0]

    /// 当前选中的地区/卷别筛选条件，默认"全部"
    @Published var selectedRegion = Paper.regions[0]

    /// 当前选中的科目筛选条件，默认"全部"
    @Published var selectedSubject = Paper.subjects[0]

    /// 从后端获取到的完整试卷列表
    @Published var papers: [Paper] = []

    /// 是否正在加载数据
    @Published var isLoading = true

    /// 加载失败时的错误提示
    @Published var errorMessage: String?

    /// 根据搜索文本与三个筛选条件计算出的当前展示试卷列表
    var filteredPapers: [Paper] {
        papers.filter { paper in
            let title = paper.title
            let matchesSearch = searchText.isEmpty || title.contains(searchText)
            let matchesYear = selectedYear == Paper.years[0] || paper.year == selectedYear
            let matchesRegion = selectedRegion == Paper.regions[0] || paper.region == selectedRegion
            let matchesSubject = selectedSubject == Paper.subjects[0] || paper.subject == selectedSubject
            return matchesSearch && matchesYear && matchesRegion && matchesSubject
        }
    }

    /// 从后端加载全部试卷列表，后续搜索与筛选在本地计算。
    /// 试卷数量可控，本地过滤可即时响应用户输入，避免频繁请求后端。
    func loadPapers() async {
        isLoading = true
        errorMessage = nil

        do {
            papers = try await APIService.shared.fetchPapers()
            print("Fetched papers: \(papers.map { $0.title })")
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// 将年份、地区、科目筛选条件重置为默认"全部"。
    func resetFilters() {
        selectedYear = Paper.years[0]
        selectedRegion = Paper.regions[0]
        selectedSubject = Paper.subjects[0]
    }

    /// 重新加载试卷列表，供重试按钮调用。
    func retry() async {
        await loadPapers()
    }
}
