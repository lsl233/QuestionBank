//
//  AppTheme.swift
//  QuestionBankApp
//
//  应用语义化配色入口。
//  业务代码优先使用这里的命名，而不是直接使用系统颜色或品牌色。
//

import SwiftUI

/// 应用主题配色命名空间。
/// 配色采用 TRAVELER'S notebook 风格：暖白背景 + 深棕文字 + 朱砂红强调。
enum AppTheme {
    /// 品牌强调色（朱砂红）
    static let accent = Color.brandCinnabar

    /// 错误/警告色（与强调色一致）
    static let error = Color.brandCinnabar

    /// 页面背景色（暖白）
    static let background = Color.warmCream

    /// 卡片背景色（奶油色）
    static let cardBackground = Color.cardCream

    /// 次要背景色（搜索框、未选中按钮等）
    static let secondaryBackground = Color.cardCream.opacity(0.8)

    /// 主文字颜色（深棕）
    static let textPrimary = Color.darkBrown

    /// 次要文字颜色（中棕）
    static let textSecondary = Color.mutedBrown

    /// 第三级文字颜色（浅棕）
    static let textTertiary = Color.lightBrown

    /// 分隔线颜色（暖棕）
    static let divider = Color.dividerBrown

    /// 深色卡片背景（Hero 卡片）
    static let darkCardBackground = Color.darkBrown
}
