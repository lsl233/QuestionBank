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
    static let brandCinnabar = Color(css: "#C73E1D")

    /// 暖白页面背景
    static let warmCream = Color(css: "#F5F1E8")

    /// 奶油色卡片背景
    static let cardCream = Color(css: "rgb(237, 232, 220)")

    /// 深棕文字/深色卡片背景
    static let darkBrown = Color(css: "#2C1810")

    /// 中棕次要文字
    static let mutedBrown = Color(css: "#6B5B50")

    /// 浅棕（箭头、占位符、弱化信息）
    static let lightBrown = Color(css: "#A89B8C")

    /// 暖棕色分隔线
    static let dividerBrown = Color(css: "#E5E0D4")
}

// MARK: - CSS 颜色构造器

extension Color {
    /// 通过 CSS 风格字符串创建颜色。
    /// 支持：
    /// - 十六进制：`"#C73E1D"`、`"#EDC"`
    /// - RGB：`"rgb(237, 232, 220)"`
    /// - RGBA：`"rgba(237, 232, 220, 0.9)"`
    init(css colorString: String) {
        let trimmed = colorString.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("#") {
            self.init(hexString: trimmed)
            return
        }

        let lowercased = trimmed.lowercased()
        if lowercased.hasPrefix("rgb(") || lowercased.hasPrefix("rgba(") {
            let content = trimmed
                .replacingOccurrences(of: "rgb(", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: "rgba(", with: "", options: .caseInsensitive)
                .replacingOccurrences(of: ")", with: "")

            let components = content.split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }

            guard components.count >= 3,
                  let r = Double(components[0]),
                  let g = Double(components[1]),
                  let b = Double(components[2]) else {
                self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
                return
            }

            let alpha = components.count >= 4 ? Double(components[3]) ?? 1.0 : 1.0
            self.init(
                .sRGB,
                red: r / 255.0,
                green: g / 255.0,
                blue: b / 255.0,
                opacity: alpha
            )
            return
        }

        self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
    }

    /// 通过十六进制字符串创建颜色，例如 `Color(hexString: "#C73E1D")`
    init(hexString: String, alpha: Double = 1.0) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        hex.removeAll { $0 == "#" }

        var rgb: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&rgb)

        let r, g, b: UInt64
        switch hex.count {
        case 3:
            r = ((rgb >> 8) & 0xF) * 17
            g = ((rgb >> 4) & 0xF) * 17
            b = (rgb & 0xF) * 17
        case 6:
            r = (rgb >> 16) & 0xFF
            g = (rgb >> 8) & 0xFF
            b = rgb & 0xFF
        default:
            r = 0; g = 0; b = 0
        }

        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: alpha
        )
    }

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
