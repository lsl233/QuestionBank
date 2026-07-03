//
//  TabRouter.swift
//  QuestionBankApp
//
//  管理底部 TabBar 的当前选中项，支持跨 Tab 跳转。
//

import SwiftUI
import Combine

/// 底部 Tab 标识。
enum AppTab: Hashable {
    case home
    case papers
    case favorites
    case profile
}

/// 全局 Tab 路由状态。
/// 在 `QuestionBankAppApp` 中作为 `StateObject` 创建并通过 `environmentObject` 注入，
/// 子视图修改 `selectedTab` 即可切换底部 Tab。
@MainActor
final class TabRouter: ObservableObject {
    @Published var selectedTab: AppTab = .home {
        didSet {
            print("[TabRouter] selectedTab changed: \(oldValue) -> \(selectedTab)")
        }
    }
}
