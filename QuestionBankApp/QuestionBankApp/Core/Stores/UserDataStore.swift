//
//  UserDataStore.swift
//  QuestionBankApp
//
//  管理当前用户的收藏、记录计数等登录态相关数据。
//

import SwiftUI
import Combine

/// 用户数据状态中心：收藏、记录计数
@MainActor
final class UserDataStore: ObservableObject {
    @Published var favoriteIDs: Set<String> = []
    @Published var profileCounts = ProfileCounts(downloadCount: 0, correctionCount: 0, studyRecordCount: 0)

    /// 从后端加载收藏列表
    func loadFavorites() async {
        do {
            let papers = try await APIService.shared.fetchFavorites()
            favoriteIDs = Set(papers.map(\.id))
        } catch APIError.unauthorized {
            favoriteIDs.removeAll()
        } catch {
            NSLog("加载收藏失败: \(error.localizedDescription)")
        }
    }

    /// 判断指定试卷是否已收藏
    func isFavorite(paperId: String) -> Bool {
        favoriteIDs.contains(paperId)
    }

    /// 切换收藏状态，返回操作后的状态
    @discardableResult
    func toggleFavorite(paper: Paper) async -> Bool {
        let currentlyFavorite = favoriteIDs.contains(paper.id)
        if currentlyFavorite {
            favoriteIDs.remove(paper.id)
            do {
                try await APIService.shared.removeFavorite(paperId: paper.id)
                return false
            } catch {
                favoriteIDs.insert(paper.id)
                NSLog("取消收藏失败: \(error.localizedDescription)")
                return true
            }
        } else {
            favoriteIDs.insert(paper.id)
            do {
                try await APIService.shared.addFavorite(paperId: paper.id)
                return true
            } catch {
                favoriteIDs.remove(paper.id)
                NSLog("添加收藏失败: \(error.localizedDescription)")
                return false
            }
        }
    }

    /// 加载我的页计数
    func loadProfileCounts() async {
        do {
            profileCounts = try await APIService.shared.fetchProfileCounts()
        } catch APIError.unauthorized {
            profileCounts = ProfileCounts(downloadCount: 0, correctionCount: 0, studyRecordCount: 0)
        } catch {
            NSLog("加载记录计数失败: \(error.localizedDescription)")
        }
    }

    /// 清空本地数据（退出登录时调用）
    func clear() {
        favoriteIDs.removeAll()
        profileCounts = ProfileCounts(downloadCount: 0, correctionCount: 0, studyRecordCount: 0)
    }
}
