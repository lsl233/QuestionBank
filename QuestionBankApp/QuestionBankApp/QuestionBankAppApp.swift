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
    @StateObject private var authManager = AuthManager()
    @StateObject private var userDataStore = UserDataStore()

    init() {
        // 全局导航栏/工具栏强调色改为朱砂红
        UINavigationBar.appearance().tintColor = UIColor(Color.brandCinnabar)
        // 列表/分组背景统一使用暖白色
        UITableView.appearance().backgroundColor = UIColor(AppTheme.background)
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }

                FavoritesView()
                    .tabItem {
                        Label("Favorites", systemImage: "star.fill")
                    }

                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
            }
            .accentColor(.brandCinnabar)
            .background(AppTheme.background.ignoresSafeArea())
            .environmentObject(authManager)
            .environmentObject(userDataStore)
        }
    }
}

#Preview {
    TabView {
        HomeView().tabItem { Label("Home", systemImage: "house") }
        FavoritesView().tabItem { Label("Favorites", systemImage: "star.fill") }
        ProfileView().tabItem { Label("Profile", systemImage: "person") }
    }
    .accentColor(.brandCinnabar)
    .environmentObject(AuthManager())
    .environmentObject(UserDataStore())
}
