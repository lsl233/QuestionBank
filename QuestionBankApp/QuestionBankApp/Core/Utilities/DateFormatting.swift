//
//  DateFormatting.swift
//  QuestionBankApp
//
//  共享日期格式化工具，用于会员有效期、创建时间等场景。
//

import Foundation

enum DateFormatting {
    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let fallbackISOFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }()

    /// 将 ISO 8601 字符串格式化为中文日期，例如 "2026年07月04日"。
    /// 解析失败时返回原字符串，避免界面出现空白。
    static func formattedDate(from isoString: String) -> String {
        guard let date = parseISO8601(isoString) else { return isoString }
        return displayFormatter.string(from: date)
    }

    /// 会员有效期专用文案："有效期至 2026年07月04日"。
    static func membershipExpirationSubtitle(_ isoString: String?) -> String {
        guard let isoString, !isoString.isEmpty else { return "已开通会员" }
        return "有效期至 \(formattedDate(from: isoString))"
    }

    private static func parseISO8601(_ string: String) -> Date? {
        isoFormatter.date(from: string) ?? fallbackISOFormatter.date(from: string)
    }
}
