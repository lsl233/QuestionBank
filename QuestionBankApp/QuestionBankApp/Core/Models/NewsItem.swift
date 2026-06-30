//
//  NewsItem.swift
//  QuestionBankApp
//
//  最新动态数据模型。
//

import Foundation

/// 首页「最新动态」卡片的数据模型
struct NewsItem: Identifiable, Codable {
    let id: String       // UUID 字符串，后端返回
    let tag: String      // 标签，如"最新"、"更新"
    let date: String     // 发布日期，格式 MM-dd
    let title: String    // 卡片标题
    let description: String // 卡片描述

    /// 映射后端 JSON 字段。
    enum CodingKeys: String, CodingKey {
        case id
        case tag
        case date
        case title
        case description
    }
}
