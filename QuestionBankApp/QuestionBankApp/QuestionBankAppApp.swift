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
    @StateObject private var tabRouter = TabRouter()

    init() {
        // 全局导航栏/工具栏强调色改为朱砂红
        UINavigationBar.appearance().tintColor = UIColor(Color.brandCinnabar)
        // 列表/分组背景统一使用暖白色
        UITableView.appearance().backgroundColor = UIColor(AppTheme.background)
    }

    var body: some Scene {
        WindowGroup {
            TabView(selection: $tabRouter.selectedTab) {
                HomeView()
                    .tabItem {
                        Label("Home", systemImage: "house")
                    }
                    .tag(AppTab.home)

                PapersView()
                    .tabItem {
                        Label("Papers", systemImage: "doc.text")
                    }
                    .tag(AppTab.papers)

                FavoritesView()
                    .tabItem {
                        Label("Favorites", systemImage: "star.fill")
                    }
                    .tag(AppTab.favorites)

                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                    .tag(AppTab.profile)
            }
            .accentColor(.brandCinnabar)
            .background(AppTheme.background.ignoresSafeArea())
            .environmentObject(authManager)
            .environmentObject(userDataStore)
            .environmentObject(tabRouter)
        }
    }
}

#Preview {
    TabView(selection: .constant(AppTab.home)) {
        HomeView().tabItem { Label("Home", systemImage: "house") }.tag(AppTab.home)
        PapersView().tabItem { Label("Papers", systemImage: "doc.text") }.tag(AppTab.papers)
        FavoritesView().tabItem { Label("Favorites", systemImage: "star.fill") }.tag(AppTab.favorites)
        ProfileView().tabItem { Label("Profile", systemImage: "person") }.tag(AppTab.profile)
    }
    .accentColor(.brandCinnabar)
    .environmentObject(AuthManager())
    .environmentObject(UserDataStore())
    .environmentObject(TabRouter())
}
