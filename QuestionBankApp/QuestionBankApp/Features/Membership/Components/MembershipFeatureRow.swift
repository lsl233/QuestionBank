//
//  MembershipFeatureRow.swift
//  QuestionBankApp
//
//  会员权益行（已包含 / 未解锁）。
//

import SwiftUI

struct MembershipFeatureRow: View {
    let title: String
    let isIncluded: Bool
    let accentColor: Color

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 3)
                    .fill(isIncluded ? accentColor : AppTheme.textPrimary.opacity(0.08))
                    .frame(width: 18, height: 18)

                Image(systemName: isIncluded ? "checkmark" : "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isIncluded ? AppTheme.background : AppTheme.textTertiary)
            }

            Text(title)
                .font(.serifChinese(.subheadline))
                .foregroundColor(isIncluded ? AppTheme.textPrimary : AppTheme.textTertiary)

            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: 8) {
        MembershipFeatureRow(title: "无限查看全部真题", isIncluded: true, accentColor: AppTheme.accent)
        MembershipFeatureRow(title: "专属学习报告", isIncluded: false, accentColor: AppTheme.accent)
    }
    .padding()
    .background(AppTheme.background)
}
