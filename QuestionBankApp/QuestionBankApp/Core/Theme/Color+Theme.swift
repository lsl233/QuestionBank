//
//  Color+Theme.swift
//  QuestionBankApp
//
//  品牌色与主题色扩展，供全局 UI 使用。
//  配色参考 TRAVELER'S notebook：暖白背景 + 深棕文字 + 朱砂红强调。
//

import SwiftUI

extension Color {
    /// 朱砂红强调色，用于标签、选中态、图标、按钮等高优先级元素
    static let brandCinnabar = Color(hex: 0xC73E1D)

    /// 暖白页面背景
    static let warmCream = Color(hex: 0xF5F1E8)

    /// 奶油色卡片背景
    static let cardCream = Color(hex: 0xFAF8F2)

    /// 深棕文字/深色卡片背景
    static let darkBrown = Color(hex: 0x2C1810)

    /// 中棕次要文字
    static let mutedBrown = Color(hex: 0x6B5B50)

    /// 浅棕（箭头、占位符、弱化信息）
    static let lightBrown = Color(hex: 0xA89B8C)

    /// 暖棕色分隔线
    static let dividerBrown = Color(hex: 0xE5E0D4)
}

// MARK: - Hex 构造器

extension Color {
    /// 通过 24 位十六进制整数创建颜色，例如 `Color(hex: 0xC73E1D)`
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
