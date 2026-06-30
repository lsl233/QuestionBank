//
//  Paper.swift
//  QuestionBankApp
//
//  高考试卷数据模型。
//

import Foundation

/// 高考试卷的数据模型
struct Paper: Identifiable, Codable, Hashable {
    let id: String       // UUID 字符串，后端返回
    let year: String     // 年份，如"2024"
    let region: String   // 地区/卷别，如"新高考I卷"
    let subject: String  // 科目，如"语文"
    let fileName: String // 对应后端 /files/:name 的文件名（不含扩展名）

    /// 列表中显示的完整标题，格式：年份·地区·科目
    var title: String {
        "\(year)·\(region)·\(subject)"
    }

    /// 映射后端 JSON 字段。
    enum CodingKeys: String, CodingKey {
        case id
        case year
        case region
        case subject
        case fileName
    }
}

// MARK: - 筛选选项

extension Paper {
    /// 年份筛选项，第一个为"全部"
    static let years = ["全部", "2026", "2024", "2023", "2022", "2021", "2020", "2019"]

    /// 地区/卷别筛选项，第一个为"全部"
    static let regions = ["全部", "全国甲卷", "全国乙卷", "新高考I卷", "新高考II卷", "北京卷"]

    /// 科目筛选项，第一个为"全部"
    static let subjects = ["全部", "语文", "数学", "英语", "物理", "化学", "生物", "历史", "地理"]
}
