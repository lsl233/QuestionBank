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
    @StateObject private var viewModel = PapersViewModel()

    /// 控制筛选 Sheet 的显示状态
    @State private var showFilterSheet = false

    var body: some View {
        NavigationStack {
            LoginGuardView(
                icon: "doc.text",
                title: "登录后浏览题库",
                onLogin: { Task { await viewModel.loadPapers() } }
            ) {
                VStack(spacing: 16) {
                    Group {
                        BilingualHeaderView(
                            englishTitle: "GAOKAO",
                            chineseTitle: "试题库",
                            style: .home
                        )

                        HStack(spacing: 12) {
                            SearchBarView(searchText: $viewModel.searchText)

                            Button {
                                showFilterSheet = true
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(AppTheme.accent)
                            }
                        }
                    }
                   

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
                .background(AppTheme.background)
                .task {
                    await viewModel.loadPapers()
                }
                .sheet(isPresented: $showFilterSheet) {
                    FilterSheetView(viewModel: viewModel)
                        .presentationDetents([.medium, .large])
                }
            }
        }

    }
}
