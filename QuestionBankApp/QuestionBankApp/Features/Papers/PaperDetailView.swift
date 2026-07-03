//
//  PaperDetailView.swift
//  QuestionBankApp
//
//  试卷详情页：顶部显示试卷名称，下方嵌入 PDF 阅读器，底部有功能按钮栏。
//

import SwiftUI

/// 试卷详情页：顶部显示试卷名称，下方嵌入 PDF 阅读器
/// 进入页面后自动把 PDF 下载到本地 Documents，再展示和分享本地文件
struct PaperDetailView: View {
    let paper: Paper

    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userDataStore: UserDataStore

    /// 控制分享面板的显示状态
    @State private var showShareSheet = false

    /// 控制勘误反馈弹窗的显示状态
    @State private var showCorrectionSheet = false

    /// 控制下载限制提示弹窗
    @State private var showDownloadRestrictionAlert = false
    @State private var downloadRestrictionMessage = ""

    /// 是否正在下载 PDF
    @State private var isDownloading = true

    /// 下载进度，0.0 ~ 1.0
    @State private var downloadProgress: Double = 0

    /// 下载完成后本地 PDF 的 URL
    @State private var localPDFURL: URL?

    /// 下载出错时的提示信息
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isDownloading {
                // 下载中：显示进度提示
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text(downloadProgress > 0 ? "正在加载 PDF \(Int(downloadProgress * 100))%" : "正在加载 PDF...")
                        .font(.serifChinese(.subheadline))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.background)
            } else if let errorMessage {
                // 下载失败：显示错误和重试
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.error)
                    Text("加载失败")
                        .font(.serifChinese(.headline, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(errorMessage)
                        .font(.serifChinese(.subheadline))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    Button("重新加载") {
                        Task { await previewPDF() }
                    }
                    .font(.serifChinese(.subheadline, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(AppTheme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 32)
                .background(AppTheme.background)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let localPDFURL {
                // 下载成功：PDF + 底部功能栏
                pdfContentView(url: localPDFURL)
            } else {
                Text("PDF 链接无效")
                    .font(.serifChinese(.subheadline))
                    .foregroundColor(AppTheme.error)
            }
        }
        .navigationTitle(paper.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(isPresented: $showShareSheet) {
            if let localPDFURL {
                // 分享本地文件，用户可选择「存储到文件」完成下载
                ShareSheet(activityItems: [localPDFURL])
            }
        }
        .sheet(isPresented: $showCorrectionSheet) {
            CorrectionSheet(paper: paper) {
                Task {
                    await userDataStore.loadProfileCounts()
                }
            }
        }
        .alert("下载受限", isPresented: $showDownloadRestrictionAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(downloadRestrictionMessage)
        }
        // 页面出现时自动预览 PDF 并记录学习
        .task {
            await previewPDF()
        }
        .onAppear {
            // 查看 3 秒后记录学习记录
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                Task {
                    try? await APIService.shared.recordStudy(paperId: paper.id, durationSec: 3)
                    await userDataStore.loadProfileCounts()
                }
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    // MARK: - PDF 内容与底部按钮栏

    /// PDF 阅读区 + 底部浮动功能按钮组
    private func pdfContentView(url: URL) -> some View {
        ZStack {
            PDFViewer(url: url)
                .edgesIgnoringSafeArea(.bottom)

            VStack {
                Spacer()
                bottomToolbar
                    .padding(.bottom, 24)
            }
        }
    }

    /// 底部浮动胶囊按钮组：收藏、下载、勘误
    private var bottomToolbar: some View {
        HStack(spacing: 4) {
            toolbarButton(
                title: "收藏",
                icon: userDataStore.isFavorite(paperId: paper.id) ? "star.fill" : "star",
                action: {
                    Task {
                        await userDataStore.toggleFavorite(paper: paper)
                    }
                }
            )

            toolbarButton(
                title: "下载",
                icon: "arrow.down.circle",
                action: { handleDownload() }
            )

            toolbarButton(
                title: "勘误",
                icon: "exclamationmark.bubble",
                action: { showCorrectionSheet = true }
            )
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(AppTheme.cardBackground)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
    }

    /// 单个底部按钮
    private func toolbarButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                Text(title)
                    .font(.serifChinese(.caption2))
            }
            .foregroundColor(AppTheme.textSecondary)
            .frame(minWidth: 56)
            .padding(.vertical, 4)
        }
    }

    // MARK: - 数据加载

    /// 免费预览 PDF：下载到本地 Documents 用于展示
    private func previewPDF() async {
        isDownloading = true
        errorMessage = nil
        localPDFURL = nil
        downloadProgress = 0

        do {
            localPDFURL = try await APIService.shared.previewPDF(fileName: paper.fileName) { progress in
                Task { @MainActor in
                    downloadProgress = progress
                }
            }
        } catch let error as APIError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }

        isDownloading = false
    }

    /// 处理「下载」按钮：未登录提示登录，未开通会员提示开通会员，会员则弹出分享并记录下载
    private func handleDownload() {
        guard authManager.isLoggedIn else {
            downloadRestrictionMessage = "请先登录后再下载试卷"
            showDownloadRestrictionAlert = true
            return
        }

        Task {
            do {
                let status = try await APIService.shared.checkMembershipStatus()
                if status.isMember {
                    // 记录下载历史并弹出分享
                    try? await APIService.shared.recordDownload(paperId: paper.id)
                    await userDataStore.loadProfileCounts()
                    await MainActor.run {
                        showShareSheet = true
                    }
                } else {
                    await MainActor.run {
                        downloadRestrictionMessage = "开通会员后即可下载试卷"
                        showDownloadRestrictionAlert = true
                    }
                }
            } catch APIError.unauthorized {
                await MainActor.run {
                    downloadRestrictionMessage = "登录已过期，请重新登录"
                    showDownloadRestrictionAlert = true
                }
            } catch {
                await MainActor.run {
                    downloadRestrictionMessage = error.localizedDescription
                    showDownloadRestrictionAlert = true
                }
            }
        }
    }
}

// MARK: - 勘误反馈弹窗

/// 试卷勘误反馈弹窗
struct CorrectionSheet: View {
    let paper: Paper
    let onSubmitted: () -> Void

    /// 用户输入的勘误内容
    @State private var content = ""

    /// 用于关闭弹窗
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("\(paper.displayTitle) 勘误反馈")
                    .font(.serifChinese(.headline, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                TextEditor(text: $content)
                    .font(.serifChinese(.body))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(8)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)

                Button("提交反馈") {
                    Task {
                        try? await APIService.shared.submitCorrection(paperId: paper.id, content: content)
                        onSubmitted()
                        dismiss()
                    }
                }
                .font(.serifChinese(.subheadline, weight: .semibold))
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(AppTheme.accent)
                .foregroundColor(.white)
                .cornerRadius(8)

                Spacer()
            }
            .padding()
            .background(AppTheme.background)
            .navigationTitle("勘误")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
    }
}
