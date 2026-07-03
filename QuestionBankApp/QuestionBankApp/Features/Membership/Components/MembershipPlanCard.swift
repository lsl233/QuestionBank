//
//  MembershipPlanCard.swift
//  QuestionBankApp
//
//  会员计划选择卡片。
//

import SwiftUI

struct MembershipPlanCard: View {
    let plan: MembershipPlan
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                iconBlock

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(plan.name)
                            .font(.serifChinese(.subheadline, weight: .semibold))
                            .foregroundColor(foregroundColor)

                        Text(plan.subtitle)
                            .font(.monoEnglish(.caption2))
                            .foregroundColor(subtitleColor)
                    }

                    Text(plan.features.prefix(2).joined(separator: " · "))
                        .font(.monoEnglish(.caption2))
                        .foregroundColor(previewColor)
                        .lineLimit(1)
                }

                Spacer()

                priceBlock
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subviews

    private var iconBlock: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? plan.color : AppTheme.textPrimary.opacity(0.08))
                .frame(width: 36, height: 36)

            Image(systemName: plan.iconName)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? AppTheme.background : AppTheme.textSecondary)
        }
    }

    private var priceBlock: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("¥\(plan.price)")
                .font(.monoEnglish(.title3, weight: .bold))
                .foregroundColor(isSelected ? plan.color : AppTheme.textPrimary)

            HStack(spacing: 4) {
                Text("¥\(plan.originalPrice)")
                    .font(.monoEnglish(.caption2))
                    .foregroundColor(AppTheme.textTertiary)
                    .strikethrough(true, color: AppTheme.textTertiary)

                Text("-\(plan.discountPercent)%")
                    .font(.monoEnglish(.caption2, weight: .medium))
                    .foregroundColor(isSelected ? AppTheme.background : AppTheme.textSecondary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(isSelected ? plan.color : AppTheme.textPrimary.opacity(0.08))
                    .cornerRadius(2)
            }

            Text(plan.unit)
                .font(.monoEnglish(.caption2))
                .foregroundColor(AppTheme.textTertiary)
        }
    }

    // MARK: - Colors

    private var foregroundColor: Color {
        isSelected && plan.id == "forever" ? AppTheme.background : AppTheme.textPrimary
    }

    private var subtitleColor: Color {
        if plan.id == "forever" && isSelected {
            return AppTheme.background.opacity(0.6)
        }
        return AppTheme.textSecondary
    }

    private var previewColor: Color {
        if plan.id == "forever" && isSelected {
            return AppTheme.background.opacity(0.5)
        }
        return AppTheme.textTertiary
    }

    private var backgroundColor: Color {
        if isSelected {
            if plan.id == "forever" {
                return AppTheme.textPrimary
            } else if plan.id == "year" {
                return AppTheme.accent.opacity(0.06)
            } else {
                return Color(hex: 0x8B7355).opacity(0.08)
            }
        }
        return AppTheme.cardBackground
    }

    private var borderColor: Color {
        isSelected ? plan.color : AppTheme.textPrimary.opacity(0.1)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 12) {
        MembershipPlanCard(plan: .allPlans[0], isSelected: false, onTap: {})
        MembershipPlanCard(plan: .allPlans[1], isSelected: true, onTap: {})
        MembershipPlanCard(plan: .allPlans[2], isSelected: false, onTap: {})
    }
    .padding()
    .background(AppTheme.background)
}
