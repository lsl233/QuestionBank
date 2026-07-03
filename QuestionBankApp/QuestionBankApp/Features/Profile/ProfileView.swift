//
//  ProfileView.swift
//  QuestionBankApp
//
//  我的 Tab：个人资料与记录入口。
//

import SwiftUI

/// 会员流程状态，用于控制购买 sheet 与成功 sheet 的切换
private enum MembershipFlow: Identifiable {
    case purchase
    case success(plan: MembershipPlan)

    var id: String {
        switch self {
        case .purchase:
            return "purchase"
        case .success(let plan):
            return "success-\(plan.id)"
        }
    }
}

private struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

struct ProfileView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userDataStore: UserDataStore

    @State private var profileCounts = ProfileCounts(
        downloadCount: 0, correctionCount: 0, studyRecordCount: 0)
    @State private var membershipStatus: MembershipStatus?
    @State private var membershipFlow: MembershipFlow?

    @State private var showDeleteConfirmation = false
    @State private var showDeleteErrorAlert = false
    @State private var deleteErrorMessage: String?
    @State private var isDeleting = false
    @State private var privacyURLItem: IdentifiableURL?

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    BilingualHeaderView(
                        englishTitle: "PROFILE",
                        chineseTitle: "我的",
                        style: .home
                    )
                    profileCard
                    menuList
                    Spacer(minLength: 40)
                    footerView
                }
                .padding(.horizontal, 16)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $membershipFlow) { flow in
            switch flow {
            case .purchase:
                MembershipPurchaseSheet { plan in
                    membershipFlow = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        membershipFlow = .success(plan: plan)
                    }
                }
            case .success(let plan):
                MembershipSuccessSheet(plan: plan) {
                    membershipFlow = nil
                }
            }
        }
        .sheet(item: $privacyURLItem) { item in
            SafariView(url: item.url)
        }
        .alert("删除账号", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                Task { await performDeleteAccount() }
            }
        } message: {
            Text("此操作不可恢复。删除后，您的收藏、下载记录、学习记录、勘误反馈和会员状态将全部清除。")
        }
        .alert("删除失败", isPresented: $showDeleteErrorAlert) {
            Button("确定", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage ?? "请检查网络后重试")
        }
        .onAppear {
            Task {
                if authManager.isLoggedIn {
                    await loadProfileCounts()
                    await loadMembershipStatus()
                }
            }
        }
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
            Button {
                membershipFlow = .purchase
            } label: {
                menuRow(
                    icon: "crown.fill",
                    title: "会员中心",
                    subtitle: membershipSubtitle
                )
            }
            .buttonStyle(PlainButtonStyle())

            NavigationLink(destination: DownloadHistoryView()) {
                menuRow(
                    icon: "arrow.down.circle",
                    title: "下载历史",
                    subtitle: "已下载 \(profileCounts.downloadCount) 套"
                )
            }
            .buttonStyle(PlainButtonStyle())

            NavigationLink(destination: CorrectionListView()) {
                menuRow(
                    icon: "exclamationmark.circle",
                    title: "错误反馈",
                    subtitle: "已提交 \(profileCounts.correctionCount) 条勘误"
                )
            }
            .buttonStyle(PlainButtonStyle())

            // NavigationLink(destination: StudyRecordView()) {
            //     menuRow(
            //         icon: "clock",
            //         title: "学习记录",
            //         subtitle: "已查看 \(profileCounts.studyRecordCount) 套试卷"
            //     )
            // }
            // .buttonStyle(PlainButtonStyle())

            Button {
                if let url = URL(string: "\(APIConfig.baseURL)/privacy") {
                    privacyURLItem = IdentifiableURL(url: url)
                }
            } label: {
                menuRow(
                    icon: "doc.text",
                    title: "隐私政策",
                    subtitle: "查看我们如何保护您的数据"
                )
            }
            .buttonStyle(PlainButtonStyle())

            Button {
                showDeleteConfirmation = true
            } label: {
                menuRow(
                    icon: "trash",
                    title: "删除账号",
                    subtitle: "永久删除账号及所有数据",
                    tint: AppTheme.error
                )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isDeleting)
        }
    }

    private var membershipSubtitle: String {
        guard authManager.isLoggedIn else {
            return "登录后开通会员"
        }
        guard let status = membershipStatus else {
            return "开通会员解锁下载"
        }
        if status.isMember {
            if status.isPermanent {
                return "已开通永久会员"
            }
            if let expiresAt = status.expiresAt {
                return "会员有效期至 \(formatDate(expiresAt))"
            }
            return "已开通会员"
        }
        return "开通会员解锁下载"
    }

    private func menuRow(
        icon: String,
        title: String,
        subtitle: String,
        tint: Color? = nil
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(tint ?? AppTheme.textSecondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.serifChinese(.headline, weight: .semibold))
                    .foregroundColor(tint ?? AppTheme.textPrimary)

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
        let days =
            calendar.dateComponents(
                [.day], from: calendar.startOfDay(for: now),
                to: calendar.startOfDay(for: gaokaoDate)
            ).day ?? 0
        return max(days, 0)
    }

    private func loadProfileCounts() async {
        do {
            profileCounts = try await APIService.shared.fetchProfileCounts()
        } catch APIError.unauthorized {
            profileCounts = ProfileCounts(downloadCount: 0, correctionCount: 0, studyRecordCount: 0)
        } catch {
            NSLog("加载记录计数失败: \(error.localizedDescription)")
        }
    }

    private func loadMembershipStatus() async {
        do {
            membershipStatus = try await APIService.shared.checkMembershipStatus()
        } catch APIError.unauthorized {
            membershipStatus = nil
        } catch {
            NSLog("加载会员状态失败: \(error.localizedDescription)")
        }
    }

    private func formatDate(_ string: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: string) else { return string }
        let output = DateFormatter()
        output.dateStyle = .medium
        output.timeStyle = .none
        return output.string(from: date)
    }

    private func performDeleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await APIService.shared.deleteAccount()
            await completeLocalCleanup()
        } catch APIError.unauthorized {
            // Token 过期或服务器端已删除，仍清理本地状态
            await completeLocalCleanup()
        } catch let error as APIError {
            deleteErrorMessage = error.localizedDescription
            showDeleteErrorAlert = true
        } catch {
            deleteErrorMessage = error.localizedDescription
            showDeleteErrorAlert = true
        }
    }

    private func completeLocalCleanup() async {
        authManager.signOut()
        userDataStore.clear()
        profileCounts = ProfileCounts(downloadCount: 0, correctionCount: 0, studyRecordCount: 0)
        membershipStatus = nil
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager())
        .environmentObject(UserDataStore())
}
