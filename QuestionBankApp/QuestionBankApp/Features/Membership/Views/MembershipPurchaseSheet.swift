//
//  MembershipPurchaseSheet.swift
//  QuestionBankApp
//
//  会员购买页 sheet。
//

import SwiftUI

struct MembershipPurchaseSheet: View {
    let onPurchaseComplete: (MembershipPlan) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan = MembershipPlan.allPlans[1]
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 24) {
                        heroSection
                        planCardsSection
                        benefitsSection
                        valueCalloutSection
                        legalTextSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }

                bottomCTABar
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("会员中心")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
        }
        .alert("支付失败", isPresented: .constant(errorMessage != nil)) {
            Button("确定", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: - Sections

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MEMBERSHIP")
                .font(.monoEnglish(.caption, weight: .medium))
                .tracking(2)
                .foregroundColor(AppTheme.textSecondary)

            Text("解锁全部历届真题 · AI 解析 · 无限下载\n陪你走过最后这段备考路")
                .font(.serifChinese(.subheadline))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var planCardsSection: some View {
        VStack(spacing: 12) {
            ForEach(MembershipPlan.allPlans) { plan in
                MembershipPlanCard(
                    plan: plan,
                    isSelected: selectedPlan.id == plan.id
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedPlan = plan
                    }
                }
            }
        }
    }

    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(selectedPlan.name.uppercased()) · 权益详情")
                .font(.monoEnglish(.caption, weight: .medium))
                .tracking(1.5)
                .foregroundColor(AppTheme.textSecondary)

            VStack(spacing: 10) {
                ForEach(selectedPlan.features, id: \.self) { feature in
                    MembershipFeatureRow(
                        title: feature,
                        isIncluded: true,
                        accentColor: selectedPlan.color
                    )
                }

                ForEach(selectedPlan.lockedFeatures, id: \.self) { feature in
                    MembershipFeatureRow(
                        title: feature,
                        isIncluded: false,
                        accentColor: selectedPlan.color
                    )
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
    }

    private var valueCalloutSection: some View {
        MembershipValueCallout(text: selectedPlan.valueCallout)
    }

    // private var paymentMethodSection: some View {
    //     VStack(alignment: .leading, spacing: 10) {
    //         Text("支付方式")
    //             .font(.monoEnglish(.caption, weight: .medium))
    //             .tracking(1.5)
    //             .foregroundColor(AppTheme.textSecondary)

    //         MembershipPaymentMethodRow()
    //     }
    // }

    private var legalTextSection: some View {
        VStack(spacing: 4) {
            Text("购买即视为同意《用户协议》与《隐私政策》")
                .font(.monoEnglish(.caption2))
                .foregroundColor(AppTheme.textTertiary)

            Text(selectedPlan.id != "forever" ? "到期不续费将自动取消" : "永久有效，不退款")
                .font(.monoEnglish(.caption2))
                .foregroundColor(AppTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bottom CTA

    private var bottomCTABar: some View {
        VStack(spacing: 8) {
            Button {
                Task { await purchaseSelectedPlan() }
            } label: {
                HStack(spacing: 8) {
                    if isPurchasing {
                        ProgressView()
                            .tint(AppTheme.background)
                    }

                    Text("立即开通  ¥\(selectedPlan.price)")
                        .font(.serifChinese(.headline, weight: .bold))

                    Text("¥\(selectedPlan.originalPrice)")
                        .font(.monoEnglish(.caption))
                        .foregroundColor(AppTheme.background.opacity(0.6))
                        .strikethrough(true, color: AppTheme.background.opacity(0.4))
                }
                .foregroundColor(AppTheme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(selectedPlan.color)
                .cornerRadius(10)
            }
            .disabled(isPurchasing)

            HStack(spacing: 4) {
                Image(systemName: "checkmark.shield")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppTheme.textTertiary)

                Text("安全支付 · 正规授权")
                    .font(.monoEnglish(.caption2))
                    .foregroundColor(AppTheme.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(AppTheme.background)
        .overlay(
            Rectangle()
                .fill(AppTheme.divider)
                .frame(height: 1),
            alignment: .top
        )
    }

    // MARK: - Actions

    private func purchaseSelectedPlan() async {
        isPurchasing = true
        errorMessage = nil

        do {
            try await StoreKitPurchaseService.shared.purchase(plan: selectedPlan)
            isPurchasing = false
            onPurchaseComplete(selectedPlan)
        } catch {
            isPurchasing = false
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    MembershipPurchaseSheet { _ in }
}
