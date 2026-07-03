//
//  MembershipSuccessSheet.swift
//  QuestionBankApp
//
//  会员开通成功页 sheet。
//

import SwiftUI

struct MembershipSuccessSheet: View {
    let plan: MembershipPlan
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.textPrimary)
                            .frame(width: 64, height: 64)

                        Image(systemName: "checkmark")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.background)
                    }

                    Text("开通成功")
                        .font(.serifChinese(.title3, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)

                    Text("\(plan.name)已激活")
                        .font(.serifChinese(.subheadline))
                        .foregroundColor(AppTheme.textSecondary)

                    Text("感谢支持 · 好好备考")
                        .font(.monoEnglish(.caption))
                        .foregroundColor(AppTheme.textTertiary)
                }

                Spacer()

                Button {
                    onDismiss()
                } label: {
                    Text("开始使用")
                        .font(.serifChinese(.headline, weight: .bold))
                        .foregroundColor(AppTheme.background)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.textPrimary)
                        .cornerRadius(10)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                }
            }
        }
    }
}

#Preview {
    MembershipSuccessSheet(plan: MembershipPlan.allPlans[1]) {}
}
