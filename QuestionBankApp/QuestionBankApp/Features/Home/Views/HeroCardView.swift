//
//  HeroCardView.swift
//  QuestionBankApp
//
//  首页深色 Hero 卡片：展示距离下次高考的天数。
//

import SwiftUI

/// 首页深色 Hero 卡片，显示高考倒计时。
struct HeroCardView: View {
    /// 下次高考日期（默认每年 6 月 7 日）
    private var targetDate: Date {
        nextGaokaoDate()
    }

    /// 距离目标日期的天数
    private var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: Date().startOfDay, to: targetDate.startOfDay).day ?? 0
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.darkCardBackground)

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("DAYS UNTIL · 高考")
                        .font(.monoEnglish(.caption, weight: .bold))
                        .foregroundColor(.mutedBrown)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(daysRemaining)")
                            .font(.serifChinese(size: 64, weight: .bold))
                            .foregroundColor(.brandCinnabar)

                        Text("天")
                            .font(.serifChinese(.title2, weight: .semibold))
                            .foregroundColor(.mutedBrown)
                    }

                    Text(dateString(from: targetDate))
                        .font(.monoEnglish(.subheadline))
                        .foregroundColor(.lightBrown)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("不积跬步")
                        .font(.serifChinese(.subheadline))
                    Text("无以至千里")
                        .font(.serifChinese(.subheadline))
                }
                .foregroundColor(.mutedBrown)
            }
            .padding(20)
        }
        .frame(height: 160)
    }

    /// 计算下一个 6 月 7 日。
    private func nextGaokaoDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        var components = DateComponents(year: year, month: 6, day: 7)
        var date = calendar.date(from: components)!

        // 如果今年的高考已过，则取明年
        if date < now.startOfDay {
            components.year = year + 1
            date = calendar.date(from: components)!
        }
        return date
    }

    /// 格式化目标日期为 "2027.06.07" 样式。
    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}

// MARK: - 辅助扩展

extension Date {
    /// 当前日期的 00:00:00 时刻，用于准确计算天数差。
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

#Preview {
    HeroCardView()
        .padding()
        .background(AppTheme.background)
}
