//
//  BilingualHeaderView.swift
//  QuestionBankApp
//
//  双语标题组件：英文小标题 + 中文大标题。
//

import SwiftUI

/// 双语标题组件。
/// 调用方通过 `style` 选择语义化尺寸，组件内部决定字体、颜色与间距。
struct BilingualHeaderView: View {
    /// 标题尺寸风格。
    enum Style {
        /// 区块标题：英文 caption2 + 中文 headline，用于首页模块、列表区块。
        case section
        /// 页面标题：英文 caption2 + 中文 largeTitle，用于「我的」等页面顶部。
        case page
        /// 首页顶部大标题：英文 caption + tracking + 中文 largeTitle，含副标题与分隔线。
        case home
    }

    let englishTitle: String
    let chineseTitle: String
    var style: Style = .section

    var body: some View {
        switch style {
        case .home:
            homeContent
        case .section, .page:
            titleStack
        }
    }

    /// 首页顶部完整标题区：双语标题 + 副标题 + 分隔线。
    private var homeContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            titleStack

            Text("历年真题 · 速查速练")
                .font(.serifChinese(.subheadline))
                .foregroundColor(.mutedBrown)

            Divider()
                .background(AppTheme.divider)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 双语标题主体。
    private var titleStack: some View {
        let config = configuration(for: style)

        return VStack(alignment: .leading, spacing: config.titleSpacing) {
            Text(englishTitle)
                .font(config.englishFont)
                .foregroundColor(config.englishColor)
                .applyTracking(config.tracking)

            Text(chineseTitle)
                .font(config.chineseFont)
                .foregroundColor(config.chineseColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .applyFixedHeight(config.fixedHeight)
    }

    private func configuration(for style: Style) -> StyleConfiguration {
        switch style {
        case .section:
            return StyleConfiguration(
                titleSpacing: 2,
                englishFont: .monoEnglish(.caption2, weight: .bold),
                chineseFont: .serifChinese(.headline, weight: .semibold),
                englishColor: .brandCinnabar,
                chineseColor: .darkBrown,
                tracking: nil,
                fixedHeight: nil
            )
        case .page:
            return StyleConfiguration(
                titleSpacing: 4,
                englishFont: .monoEnglish(.caption2, weight: .bold),
                chineseFont: .serifChinese(.largeTitle, weight: .bold),
                englishColor: AppTheme.accent,
                chineseColor: AppTheme.textPrimary,
                tracking: nil,
                fixedHeight: nil
            )
        case .home:
            return StyleConfiguration(
                titleSpacing: 0,
                englishFont: .monoEnglish(.caption, weight: .bold),
                chineseFont: .serifChinese(.largeTitle, weight: .black),
                englishColor: .brandCinnabar,
                chineseColor: .darkBrown,
                tracking: 3,
                fixedHeight: nil
            )
        }
    }
}

// MARK: - Style Configuration

private struct StyleConfiguration {
    let titleSpacing: CGFloat
    let englishFont: Font
    let chineseFont: Font
    let englishColor: Color
    let chineseColor: Color
    let tracking: CGFloat?
    let fixedHeight: CGFloat?
}

// MARK: - View Helpers

private extension View {
    @ViewBuilder
    func applyTracking(_ tracking: CGFloat?) -> some View {
        if let tracking {
            self.tracking(tracking)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyFixedHeight(_ height: CGFloat?) -> some View {
        if let height {
            self.frame(height: height, alignment: .leading)
        } else {
            self
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        BilingualHeaderView(englishTitle: "LATEST QUESTIONS", chineseTitle: "最新试题")

        BilingualHeaderView(
            englishTitle: "GAOKAO",
            chineseTitle: "高考真题",
            style: .home
        )
    }
    .padding()
}
