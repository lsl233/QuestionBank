//
//  PDFViewer.swift
//  QuestionBankApp
//
//  基于 PDFKit 的 PDF 阅读器。
//

import SwiftUI
import PDFKit

/// 基于 PDFKit 的 PDF 阅读器
/// 将 UIKit 的 PDFView 包装为 SwiftUI 可用的 UIViewRepresentable
struct PDFViewer: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true               // 自动缩放以适应屏幕宽度
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        pdfView.usePageViewController(false)    // 避免 UIPageViewController 同时持有多个页面导致内存暴涨
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pdfView.isUserInteractionEnabled = true
        pdfView.backgroundColor = UIColor(AppTheme.background)
        return pdfView
    }

    func updateUIView(_ pdfView: PDFView, context: Context) {
        // 只在 document 尚未设置时才创建，避免重复构造 PDFDocument
        guard pdfView.document == nil else { return }

        // 用本地 PDF 文件创建 PDFDocument
        if let document = PDFDocument(url: url) {
            pdfView.document = document
        }
    }

    static func dismantleUIView(_ pdfView: PDFView, coordinator: ()) {
        // 视图销毁时主动释放 PDFDocument，降低内存峰值
        pdfView.document = nil
    }
}
