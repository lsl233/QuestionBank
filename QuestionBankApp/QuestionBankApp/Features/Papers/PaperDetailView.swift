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
    let paperName: String

    /// 控制分享面板的显示状态
    @State private var showShareSheet = false

    /// 控制勘误反馈弹窗的显示状态
    @State private var showCorrectionSheet = false

    /// 当前试卷是否已收藏
    @State private var isFavorite = false

    /// 是否正在下载 PDF
    @State private var isDownloading = true

    /// 下载进度，0.0 ~ 1.0
    @State private var downloadProgress: Double = 0

    /// 下载完成后本地 PDF 的 URL
    @State private var localPDFURL: URL?

    /// 下载出错时的提示信息
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
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
                            Task { await downloadPDF() }
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
                } else if let localPDFURL {
                    // 下载成功：PDF + 底部功能栏
                    pdfContentView(url: localPDFURL)
                } else {
                    Text("PDF 链接无效")
                        .font(.serifChinese(.subheadline))
                        .foregroundColor(AppTheme.error)
                }
            }
            .navigationTitle(paperName)
            .sheet(isPresented: $showShareSheet) {
                if let localPDFURL {
                    // 分享本地文件，用户可选择「存储到文件」完成下载
                    ShareSheet(activityItems: [localPDFURL])
                }
            }
            .sheet(isPresented: $showCorrectionSheet) {
                CorrectionSheet(paperName: paperName)
            }
            // 页面出现时自动下载 PDF
            .task {
                await downloadPDF()
            }
        }
        .background(AppTheme.background.ignoresSafeArea())
    }

    // MARK: - PDF 内容与底部按钮栏

    /// PDF 阅读区 + 底部功能按钮栏
    private func pdfContentView(url: URL) -> some View {
        VStack(spacing: 0) {
            PDFViewer(url: url)
                .edgesIgnoringSafeArea(.bottom)

            bottomToolbar
        }
    }

    /// 底部功能按钮栏：收藏、下载、勘误
    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            toolbarButton(
                title: "收藏",
                icon: isFavorite ? "star.fill" : "star",
                action: { isFavorite.toggle() }
            )

            toolbarButton(
                title: "下载",
                icon: "arrow.down.circle",
                action: { showShareSheet = true }
            )

            toolbarButton(
                title: "勘误",
                icon: "exclamationmark.bubble",
                action: { showCorrectionSheet = true }
            )
        }
        .padding(.vertical, 10)
        .background(AppTheme.cardBackground)
        // 顶部一条细腻分隔线
        .overlay(Divider().background(AppTheme.divider), alignment: .top)
    }

    /// 单个底部按钮
    private func toolbarButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                Text(title)
                    .font(.serifChinese(.caption2))
            }
            .foregroundColor(AppTheme.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - 数据加载

    /// 调用 APIService 把 PDF 下载到本地 Documents
    private func downloadPDF() async {
        isDownloading = true
        errorMessage = nil
        localPDFURL = nil
        downloadProgress = 0

        do {
            localPDFURL = try await APIService.shared.downloadPDF(fileName: paperName) { progress in
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
}

// MARK: - 勘误反馈弹窗

/// 试卷勘误反馈弹窗（占位实现）
struct CorrectionSheet: View {
    let paperName: String

    /// 用户输入的勘误内容
    @State private var content = ""

    /// 用于关闭弹窗
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("\(paperName) 勘误反馈")
                    .font(.serifChinese(.headline, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                TextEditor(text: $content)
                    .font(.serifChinese(.body))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(8)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)

                Button("提交反馈") {
                    // TODO: 调用后端接口提交勘误内容
                    dismiss()
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
