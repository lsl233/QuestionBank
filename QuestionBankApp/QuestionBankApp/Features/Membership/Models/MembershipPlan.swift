//
//  MembershipPlan.swift
//  QuestionBankApp
//
//  会员计划数据模型。
//

import SwiftUI

/// 会员计划
struct MembershipPlan: Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let appleProductId: String
    let price: Int
    let originalPrice: Int
    let unit: String
    let features: [String]
    let lockedFeatures: [String]
    let badge: String?
    let color: Color
    let iconName: String
    let perDay: String
    let valueCallout: String

    /// 折扣百分比，如 40 表示 4 折 / 60% off
    var discountPercent: Int {
        guard originalPrice > 0 else { return 0 }
        return Int((1.0 - Double(price) / Double(originalPrice)) * 100)
    }
}

extension MembershipPlan {
    static let allPlans: [MembershipPlan] = [
        MembershipPlan(
            id: "month",
            name: "月度会员",
            subtitle: "灵活试用",
            appleProductId: "com.lsl.QuestionBankApp.membership.month",
            price: 6,
            originalPrice: 10,
            unit: "/ 月",
            features: [
                "无限查看全部真题",
                "PDF 下载 · 5套/月",
                "收藏夹无限制"
            ],
            lockedFeatures: [
                "错题 AI 解析",
                "历年答案详解",
                "专属学习报告"
            ],
            badge: nil,
            color: Color(hex: 0x8B7355),
            iconName: "bolt.fill",
            perDay: "0.2",
            valueCallout: "灵活体验，随时可升级 · 比一杯奶茶少一点"
        ),
        MembershipPlan(
            id: "year",
            name: "年度会员",
            subtitle: "最受欢迎",
            appleProductId: "com.lsl.QuestionBankApp.membership.year",
            price: 68,
            originalPrice: 120,
            unit: "/ 年",
            features: [
                "无限查看全部真题",
                "PDF 下载 · 无限制",
                "收藏夹无限制",
                "错题 AI 解析",
                "历年答案详解"
            ],
            lockedFeatures: [
                "专属学习报告"
            ],
            badge: "推荐",
            color: Color.brandCinnabar,
            iconName: "crown.fill",
            perDay: "0.19",
            valueCallout: "相比原价节省 ¥52 · 每天不到 ¥0.19"
        ),
        MembershipPlan(
            id: "forever",
            name: "永久会员",
            subtitle: "一次拥有",
            appleProductId: "com.lsl.QuestionBankApp.membership.permanent",
            price: 198,
            originalPrice: 360,
            unit: "买断",
            features: [
                "无限查看全部真题",
                "PDF 下载 · 无限制",
                "收藏夹无限制",
                "错题 AI 解析",
                "历年答案详解",
                "专属学习报告"
            ],
            lockedFeatures: [],
            badge: "最划算",
            color: Color.darkBrown,
            iconName: "infinity",
            perDay: "无限",
            valueCallout: "一次买断，终身使用 · 相比年度仅多 ¥130，永久有效"
        )
    ]
}
