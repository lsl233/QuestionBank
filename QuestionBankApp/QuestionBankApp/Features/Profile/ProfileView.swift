//
//  ProfileView.swift
//  QuestionBankApp
//
//  我的 Tab：个人资料与记录入口。
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userDataStore: UserDataStore

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    headerView
                    profileCard
                    menuList
                    Spacer(minLength: 40)
                    footerView
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            Task {
                if authManager.isLoggedIn {
                    await userDataStore.loadProfileCounts()
                }
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("PROFILE")
                .font(.monoEnglish(.caption2, weight: .bold))
                .foregroundColor(AppTheme.accent)
            Text("我的")
                .font(.serifChinese(.largeTitle, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var profileCard: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.textPrimary)
                    .frame(width: 64, height: 64)
                Text("高")
                    .font(.serifChinese(.title2, weight: .bold))
                    .foregroundColor(AppTheme.background)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("备考学生")
                    .font(.serifChinese(.title3, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Text("距高考 \(daysUntilGaokao) 天")
                    .font(.monoEnglish(.subheadline))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
    }

    private var menuList: some View {
        VStack(spacing: 12) {
            NavigationLink(destination: DownloadHistoryView()) {
                menuRow(
                    icon: "arrow.down.circle",
                    title: "下载历史",
                    subtitle: "已下载 \(userDataStore.profileCounts.downloadCount) 套"
                )
            }
            .buttonStyle(PlainButtonStyle())

            NavigationLink(destination: CorrectionListView()) {
                menuRow(
                    icon: "exclamationmark.circle",
                    title: "错误反馈",
                    subtitle: "已提交 \(userDataStore.profileCounts.correctionCount) 条勘误"
                )
            }
            .buttonStyle(PlainButtonStyle())

            NavigationLink(destination: StudyRecordView()) {
                menuRow(
                    icon: "clock",
                    title: "学习记录",
                    subtitle: "已查看 \(userDataStore.profileCounts.studyRecordCount) 套试卷"
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func menuRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.serifChinese(.headline, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)

                Text(subtitle)
                    .font(.monoEnglish(.caption))
                    .foregroundColor(AppTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.textTertiary)
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
    }

    private var footerView: some View {
        Text("历届真题库 v1.0 · 高考备考手记")
            .font(.monoEnglish(.caption2))
            .foregroundColor(AppTheme.textTertiary)
    }

    private var daysUntilGaokao: Int {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        let components = DateComponents(year: currentYear + 1, month: 6, day: 7)
        guard let gaokaoDate = calendar.date(from: components) else { return 0 }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: now), to: calendar.startOfDay(for: gaokaoDate)).day ?? 0
        return max(days, 0)
    }
}
