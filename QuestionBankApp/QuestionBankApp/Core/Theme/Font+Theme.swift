//
//  Font+Theme.swift
//  QuestionBankApp
//
//  自定义字体扩展。
//  英文使用 Space Mono；中文使用思源宋体（Source Han Serif CN Regular）。
//  如需更多字重（Bold/SemiBold），将字体文件加入 Resources/Fonts 并在 CustomFont 中注册。
//

import SwiftUI

/// 自定义字体名称枚举，便于集中管理。
enum CustomFont: String {
    /// Space Mono Regular
    case spaceMonoRegular = "SpaceMono-Regular"
}

extension Font {
    // MARK: - 中文宋体

    /// 中文宋体字体（按 TextStyle）。
    /// 真机加载 11MB 的 Source Han Serif 会导致内存压力被系统终止，
    /// 因此改用系统自带的 serif 设计，视觉上仍为宋体风格且零额外内存开销。
    static func serifChinese(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        Font.system(style, design: .serif)
            .weight(weight)
    }

    /// 中文宋体字体（按固定字号）。
    static func serifChinese(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .serif)
    }

    // MARK: - 英文等宽

    /// 英文等宽字体（Space Mono）。
    /// 目前只注册了 Regular 字重，加粗由 SwiftUI 合成；后续可补充 SpaceMono-Bold.ttf。
    static func monoEnglish(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        Font.custom(CustomFont.spaceMonoRegular.rawValue, size: sizeFor(style), relativeTo: style)
            .weight(weight)
    }

    /// 英文等宽字体（按固定字号）。
    static func monoEnglish(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom(CustomFont.spaceMonoRegular.rawValue, fixedSize: size)
            .weight(weight)
    }

    // MARK: - 字号映射

    /// 将 SwiftUI TextStyle 映射到参考点大小，用于自定义字体。
    private static func sizeFor(_ style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .subheadline: return 15
        case .body: return 17
        case .callout: return 16
        case .footnote: return 13
        case .caption: return 12
        case .caption2: return 11
        @unknown default: return 17
        }
    }
}
