//
//  FilterSectionView.swift
//  QuestionBankApp
//
//  通用筛选区块组件：标题 + 自动换行的胶囊按钮。
//

import SwiftUI

/// 通用筛选区块组件：标题 + 自动换行的胶囊按钮
/// - 可用于年份、地区、科目等任意一组互斥选项
struct FilterSectionView: View {
    let title: String
    let options: [String]
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.serifChinese(.subheadline))
                .foregroundColor(AppTheme.textSecondary)

            FlowLayout(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        Text(option)
                            .font(.serifChinese(.subheadline, weight: selection == option ? .semibold : .regular))
                            .foregroundColor(selection == option ? .white : AppTheme.textPrimary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selection == option ? AppTheme.textPrimary : AppTheme.cardBackground)
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Flow Layout

/// 简单的流式布局：子视图按行排列，超出宽度时自动换行。
private struct FlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(
                at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY),
                proposal: .unspecified
            )
        }
    }

    private struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }
                frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

#Preview {
    FilterSectionView(
        title: "年份",
        options: ["全部", "2024", "2023", "2022", "2021"],
        selection: .constant("全部")
    )
    .padding()
    .background(AppTheme.background)
}
