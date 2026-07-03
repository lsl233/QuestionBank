//
//  MembershipPaymentMethodRow.swift
//  QuestionBankApp
//
//  支付方式展示行（当前仅展示 Apple Pay）。
//

import SwiftUI

struct MembershipPaymentMethodRow: View {
    var body: some View {
        HStack(spacing: 12) {
            applePayIcon

            Text("Apple Pay")
                .font(.serifChinese(.subheadline, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)

            Spacer()

            HStack(spacing: 4) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color(hex: 0x5C7A4E))

                Text("Face ID 验证")
                    .font(.monoEnglish(.caption2))
                    .foregroundColor(Color(hex: 0x5C7A4E))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(AppTheme.background.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(AppTheme.textPrimary, lineWidth: 1.5)
        )
        .cornerRadius(6)
    }

    private var applePayIcon: some View {
        Image(systemName: "apple.logo")
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(AppTheme.textPrimary)
            .frame(width: 22, height: 22)
    }
}

#Preview {
    MembershipPaymentMethodRow()
        .padding()
        .background(AppTheme.background)
}
