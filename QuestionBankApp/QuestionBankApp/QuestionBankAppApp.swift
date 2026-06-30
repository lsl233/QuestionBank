//
//  QuestionBankAppApp.swift
//  QuestionBankApp
//
//  Created by xxx on 2026/6/27.
//

import SwiftUI
import UIKit

@main
struct QuestionBankAppApp: App {

    init() {
        // 全局导航栏/工具栏强调色改为朱砂红
        UINavigationBar.appearance().tintColor = UIColor(Color.brandCinnabar)
        // 列表/分组背景统一使用暖白色
        UITableView.appearance().backgroundColor = UIColor(AppTheme.background)
    }

    var body: some Scene {
        WindowGroup {
            // 应用启动后直接进入首页
            HomeView()
                .background(AppTheme.background.ignoresSafeArea())
        }
    }
}
