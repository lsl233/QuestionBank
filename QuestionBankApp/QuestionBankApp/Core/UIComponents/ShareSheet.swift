//
//  ShareSheet.swift
//  QuestionBankApp
//
//  包装 UIActivityViewController，用于在 SwiftUI 中弹出系统分享面板。
//

import SwiftUI

/// 包装 UIActivityViewController，用于在 SwiftUI 中弹出系统分享/下载面板
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
