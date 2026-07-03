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
    let examType: String // 考试类型，如"普通高考"
    let region: String   // 地区/卷别，如"新高考I卷"
    let subject: String  // 科目，如"语文"
    let stream: String?  // 文/理分科，旧课程试卷使用
    let note: String?    // 额外备注
    let fileName: String // 对应后端 /files/:name 的文件名（不含扩展名）
    let title: String    // 后端展示标题，如"2024年全国甲卷·语文"
    let viewCount: Int   // 查看次数
    let createdAt: String? // 后端创建时间，ISO 8601 字符串

    /// 列表中显示的完整标题，服务端未返回时兜底
    var displayTitle: String {
        title.isEmpty ? "\(year)·\(region)·\(subject)" : title
    }
}

// MARK: - 筛选选项

extension Paper {
    /// 年份筛选项，第一个为"全部"
    static let years = ["全部", "2024", "2023", "2022", "2021", "2020", "2019", "2018", "2017", "2016", "2015"]

    /// 地区/卷别筛选项，第一个为"全部"
    static let regions = ["全部", "全国甲卷", "全国乙卷", "新高考Ⅰ卷", "新高考Ⅱ卷", "北京", "上海", "广东", "浙江", "山东"]

    /// 科目筛选项，第一个为"全部"
    static let subjects = ["全部", "语文", "数学(理)", "数学(文)", "英语", "物理", "化学", "生物", "历史", "地理", "政治"]
}
