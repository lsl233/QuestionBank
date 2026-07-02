//
//  PapersView.swift
//  QuestionBankApp
//
//  题库 Tab：提供搜索、年份/地区/科目筛选与完整试卷列表。
//

import SwiftUI

/// 题库 Tab 主视图。
/// 集中展示所有试卷，并支持搜索与多维筛选。
struct PapersView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userDataStore: UserDataStore
    @StateObject private var viewModel = PapersViewModel()

    var body: some View {
        NavigationStack {
            LoginGuardView(
                icon: "doc.text",
                title: "登录后浏览题库",
                onLogin: { Task { await viewModel.loadPapers() } }
            ) {
                VStack(spacing: 16) {
                    SearchBarView(searchText: $viewModel.searchText)

                    FilterSectionView(
                        title: "年份",
                        options: Paper.years,
                        selection: $viewModel.selectedYear
                    )

                    FilterSectionView(
                        title: "地区",
                        options: Paper.regions,
                        selection: $viewModel.selectedRegion
                    )

                    FilterSectionView(
                        title: "科目",
                        options: Paper.subjects,
                        selection: $viewModel.selectedSubject
                    )

                    AsyncListContainerView(
                        isLoading: viewModel.isLoading,
                        errorMessage: viewModel.errorMessage,
                        items: viewModel.filteredPapers,
                        emptyIcon: "doc.text.magnifyingglass",
                        emptyText: "没有找到相关试卷",
                        onRetry: { Task { await viewModel.loadPapers() } }
                    ) { paper in
                        PaperRowCell(paper: paper)
                    }
                    .frame(maxHeight: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .navigationTitle("Papers")
                .navigationBarTitleDisplayMode(.large)
                .task {
                    await viewModel.loadPapers()
                }
            }
        }
    }
}

#Preview {
    PapersView()
        .environmentObject(AuthManager())
        .environmentObject(UserDataStore())
}
