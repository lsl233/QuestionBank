//
//  MembershipValueCallout.swift
//  QuestionBankApp
//
//  会员价值提醒卡片。
//

import SwiftUI

struct MembershipValueCallout: View {
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.accent)

            Text(text)
                .font(.serifChinese(.caption))
                .foregroundColor(AppTheme.accent)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(12)
        .background(AppTheme.accent.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(AppTheme.accent.opacity(0.15), lineWidth: 1)
        )
        .cornerRadius(6)
    }
}

#Preview {
    MembershipValueCallout(text: "相比原价节省 ¥52 · 每天不到 ¥0.19")
        .padding()
        .background(AppTheme.background)
}
