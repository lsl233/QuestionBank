//
//  APIService.swift
//  QuestionBankApp
//
//  负责所有后端接口的网络请求封装。
//  使用 Swift 原生的 URLSession + async/await，不依赖第三方库。
//

import Foundation

/// 后端地址配置。
/// 开发模拟器运行时使用 localhost；
/// 如果用真机测试，需要改成电脑的局域网 IP，例如 "http://192.168.1.5:3000"。
enum APIConfig {
    static let baseURL = "http://localhost:3000"
}

/// 打印调试信息到系统日志，方便在 Console.app 或 simctl log 中查看。
/// 使用 NSLog 而不是 print，因为 print 不会写入系统日志。
private func logRequest(_ message: String) {
    NSLog("【网络请求】%@", message)
}

/// 网络请求中可能出现的错误类型，方便上层显示友好的提示。
enum APIError: Error, LocalizedError {
    case invalidURL           // URL 构造失败
    case invalidResponse      // 服务器返回非 200 状态码
    case decodingFailed       // JSON 解析失败
    case unauthorized         // 401，未登录或 token 过期
    case unknown              // 其他未知错误

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "接口地址无效"
        case .invalidResponse:
            return "服务器响应异常"
        case .decodingFailed:
            return "数据解析失败"
        case .unauthorized:
            return "登录已过期，请重新登录"
        case .unknown:
            return "未知错误"
        }
    }
}

/// 后端 API 请求封装。
/// 所有网络请求都走这里，保持视图层代码简洁。
final class APIService {

    /// 单例，全局共享一个 APIService 实例即可。
    static let shared = APIService()

    /// 使用自定义超时的 URLSession，避免真机上网络异常时无限 loading。
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        // 等待服务器响应/数据的超时
        config.timeoutIntervalForRequest = 30
        // 整个下载/请求资源的最长耗时
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }()

    /// 当前登录 token，从 Keychain 读取
    private var token: String? {
        KeychainTokenStore.load()
    }

    private init() {}

    // MARK: - 认证

    /// Apple 登录换取后端 JWT
    func signInWithApple(
        identityToken: String,
        email: String?,
        givenName: String?,
        familyName: String?
    ) async throws -> String {
        let body: [String: Any?] = [
            "identityToken": identityToken,
            "email": email,
            "givenName": givenName,
            "familyName": familyName,
        ]
        let data = try await request(path: "/auth/apple", method: "POST", body: body.compactMapValues { $0 })
        let response = try JSONDecoder().decode(SignInResponse.self, from: data)
        return response.token
    }

    /// 测试环境一键登录，仅 DEBUG 构建使用
    func testLogin() async throws -> String {
        let data = try await request(path: "/auth/test-login", method: "POST")
        let response = try JSONDecoder().decode(SignInResponse.self, from: data)
        return response.token
    }

    // MARK: - 试卷

    /// 获取试卷列表。
    /// - Parameters:
    ///   - year: 年份，传 nil 或 "全部" 表示不筛选
    ///   - region: 地区/卷别，传 nil 或 "全部" 表示不筛选
    ///   - subject: 科目，传 nil 或 "全部" 表示不筛选
    ///   - search: 搜索关键字，传 nil 表示不搜索
    /// - Returns: 试卷数组
    func fetchPapers(
        year: String? = nil,
        region: String? = nil,
        subject: String? = nil,
        search: String? = nil
    ) async throws -> [Paper] {
        // 1. 构造查询参数
        var queryItems: [URLQueryItem] = []

        if let year = year, year != "全部", !year.isEmpty {
            queryItems.append(URLQueryItem(name: "year", value: year))
        }
        if let region = region, region != "全部", !region.isEmpty {
            queryItems.append(URLQueryItem(name: "region", value: region))
        }
        if let subject = subject, subject != "全部", !subject.isEmpty {
            queryItems.append(URLQueryItem(name: "subject", value: subject))
        }
        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }

        // 2. 发送请求并解析
        let data = try await request(path: "/papers", queryItems: queryItems)

        // 3. 后端返回 { "papers": [...] }，这里只取 papers 数组
        let response = try JSONDecoder().decode(PapersResponse.self, from: data)
        return response.papers
    }

    /// 获取单张试卷详情。
    /// - Parameter id: 试卷 UUID
    /// - Returns: 试卷对象
    func fetchPaper(id: String) async throws -> Paper {
        let data = try await request(path: "/papers/\(id)")
        let response = try JSONDecoder().decode(PaperResponse.self, from: data)
        return response.paper
    }

    // MARK: - 新闻

    /// 获取新闻公告列表。
    /// - Returns: 新闻数组
    func fetchNews() async throws -> [NewsItem] {
        let data = try await request(path: "/news")
        let response = try JSONDecoder().decode(NewsResponse.self, from: data)
        return response.news
    }

    // MARK: - 收藏

    func fetchFavorites() async throws -> [Paper] {
        let data = try await authenticatedRequest(path: "/favorites")
        let response = try JSONDecoder().decode(FavoritesResponse.self, from: data)
        return response.favorites.compactMap(\.paper)
    }

    func addFavorite(paperId: String) async throws {
        let body: [String: Any] = ["paperId": paperId]
        _ = try await authenticatedRequest(path: "/favorites", method: "POST", body: body)
    }

    func removeFavorite(paperId: String) async throws {
        _ = try await authenticatedRequest(path: "/favorites/\(paperId)", method: "DELETE")
    }

    // MARK: - 下载历史

    func recordDownload(paperId: String) async throws {
        let body: [String: Any] = ["paperId": paperId]
        _ = try await authenticatedRequest(path: "/downloads", method: "POST", body: body)
    }

    // MARK: - 勘误反馈

    func submitCorrection(paperId: String, content: String) async throws {
        let body: [String: Any] = [
            "paperId": paperId,
            "content": content,
        ]
        _ = try await authenticatedRequest(path: "/corrections", method: "POST", body: body)
    }

    // MARK: - 学习记录

    func recordStudy(paperId: String, durationSec: Int) async throws {
        let body: [String: Any] = [
            "paperId": paperId,
            "durationSec": durationSec,
        ]
        _ = try await authenticatedRequest(path: "/study-records", method: "POST", body: body)
    }

    // MARK: - 会员状态

    func checkMembershipStatus() async throws -> MembershipStatus {
        let data = try await authenticatedRequest(path: "/membership/status")
        return try JSONDecoder().decode(MembershipStatus.self, from: data)
    }

    /// 将会员购买成功的 StoreKit JWS 交易信息提交给服务端激活会员。
    func verifyApplePurchase(jws: String) async throws {
        let body: [String: Any] = ["signedTransactionJws": jws]
        let data = try await authenticatedRequest(
            path: "/membership/apple/verify",
            method: "POST",
            body: body
        )

        let response = try JSONDecoder().decode(VerifyPurchaseResponse.self, from: data)
        guard response.success else {
            throw MembershipPurchaseError.serverVerifyFailed(response.message ?? "会员激活失败，请稍后再试")
        }
    }

    // MARK: - 账号

    func deleteAccount() async throws {
        _ = try await authenticatedRequest(path: "/account", method: "DELETE")
    }

    // MARK: - 我的页计数

    func fetchProfileCounts() async throws -> ProfileCounts {
        async let downloads = count(path: "/downloads/count")
        async let corrections = count(path: "/corrections/count")
        async let studies = count(path: "/study-records/count")
        return ProfileCounts(
            downloadCount: try await downloads,
            correctionCount: try await corrections,
            studyRecordCount: try await studies
        )
    }

    private func count(path: String) async throws -> Int {
        let data = try await authenticatedRequest(path: path)
        let response = try JSONDecoder().decode(CountResponse.self, from: data)
        return response.count
    }

    // MARK: - PDF 预览与下载

    /// 预览 PDF：免费接口，用于 App 内查看。
    func previewPDF(fileName: String, progress: @escaping (Double) -> Void) async throws -> URL {
        guard let encodedFileName = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let remoteURL = URL(string: "\(APIConfig.baseURL)/files/\(encodedFileName)/preview") else {
            throw APIError.invalidURL
        }

        logRequest("开始预览 PDF: \(remoteURL.absoluteString)")
        print(remoteURL.absoluteString)

        return try await savePDF(from: remoteURL, progress: progress)
    }

    /// 下载 PDF：会员接口，用于触发「保存/分享」行为。
    func downloadPDF(fileName: String, progress: @escaping (Double) -> Void) async throws -> URL {
        guard let encodedFileName = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let remoteURL = URL(string: "\(APIConfig.baseURL)/files/\(encodedFileName)") else {
            throw APIError.invalidURL
        }

        logRequest("开始下载 PDF: \(remoteURL.absoluteString)")
        print(remoteURL.absoluteString)

        return try await savePDF(from: remoteURL, progress: progress)
    }

    /// 通用 PDF 保存逻辑：流式下载到 Documents 目录。
    private func savePDF(from remoteURL: URL, progress: @escaping (Double) -> Void) async throws -> URL {
        // 1. 流式下载并写入本地文件，同时上报进度
        let (asyncBytes, response) = try await session.bytes(from: remoteURL)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            logRequest("下载 PDF 失败，状态码: \(statusCode)")
            throw APIError.invalidResponse
        }

        // 2. 确定保存路径：Documents/{uuid}.pdf
        // 使用纯 ASCII 的本地文件名，避免 PDFKit 在真机上因中文路径/特殊字符出现解析问题
        guard let documentsURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first else {
            throw APIError.unknown
        }
        let localFileName = "\(UUID().uuidString).pdf"
        let savedURL = documentsURL.appendingPathComponent(localFileName)

        // 3. 如果文件已存在则先删除
        if FileManager.default.fileExists(atPath: savedURL.path) {
            try FileManager.default.removeItem(at: savedURL)
        }

        // 4. 创建空文件并流式写入
        FileManager.default.createFile(atPath: savedURL.path, contents: nil, attributes: nil)
        let fileHandle = try FileHandle(forWritingTo: savedURL)
        defer { try? fileHandle.close() }

        let totalBytes = httpResponse.expectedContentLength
        var downloadedBytes: Int64 = 0
        var buffer = Data()
        buffer.reserveCapacity(64 * 1024)

        for try await byte in asyncBytes {
            buffer.append(byte)
            if buffer.count >= 64 * 1024 {
                try fileHandle.write(contentsOf: buffer)
                downloadedBytes += Int64(buffer.count)
                if totalBytes > 0 {
                    progress(Double(downloadedBytes) / Double(totalBytes))
                }
                buffer.removeAll(keepingCapacity: true)
            }
        }

        if !buffer.isEmpty {
            try fileHandle.write(contentsOf: buffer)
            downloadedBytes += Int64(buffer.count)
            if totalBytes > 0 {
                progress(Double(downloadedBytes) / Double(totalBytes))
            }
        }

        // 5. 校验下载内容确实是 PDF
        guard isPDF(at: savedURL) else {
            logRequest("下载的文件不是有效的 PDF: \(savedURL.path)")
            throw APIError.decodingFailed
        }

        logRequest("PDF 已保存到: \(savedURL.path)")
        return savedURL
    }

    /// 检查文件开头是否为 PDF 魔数 "%PDF"
    private func isPDF(at url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: 4), data.count == 4 else { return false }
        return data == Data("%PDF".utf8)
    }

    // MARK: - 底层请求方法

    /// 通用的 GET 请求方法。
    /// - Parameters:
    ///   - path: 接口路径，例如 "/papers"
    ///   - queryItems: 查询参数
    /// - Returns: 服务器返回的原始 Data
    private func request(path: String, method: String = "GET", queryItems: [URLQueryItem] = [], body: [String: Any]? = nil) async throws -> Data {
        // 1. 构造完整 URL
        guard var components = URLComponents(string: APIConfig.baseURL + path) else {
            throw APIError.invalidURL
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        // 2. 构造请求
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        if let body = body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }

        // 3. 打印请求信息，方便调试
        logRequest("URL: \(url.absoluteString)")
        if !queryItems.isEmpty {
            let params = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
            logRequest("参数: \(params)")
        }

        // 4. 发送请求
        let (data, response) = try await session.data(for: urlRequest)

        // 5. 检查 HTTP 状态码
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard httpResponse.statusCode == 200 else {
            let statusCode = httpResponse.statusCode
            logRequest("错误状态码: \(statusCode)")
            throw APIError.invalidResponse
        }

        // 6. 打印返回数据（转成字符串方便查看）
        if let jsonString = String(data: data, encoding: .utf8) {
            logRequest("返回数据: \(jsonString)")
        }

        return data
    }

    /// 需要登录态的请求，自动附加 Authorization 头
    func authenticatedRequest(path: String, method: String = "GET", queryItems: [URLQueryItem] = [], body: [String: Any]? = nil) async throws -> Data {
        guard let token = token else {
            throw APIError.unauthorized
        }

        // 在 body/query 之外注入 header
        guard var components = URLComponents(string: APIConfig.baseURL + path) else {
            throw APIError.invalidURL
        }
        components.queryItems = queryItems.isEmpty ? nil : queryItems

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        if let body = body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        }

        logRequest("[AUTH] URL: \(url.absoluteString)")

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard httpResponse.statusCode == 200 else {
            logRequest("[AUTH] 错误状态码: \(httpResponse.statusCode)")
            throw APIError.invalidResponse
        }

        return data
    }
}

// MARK: - 后端响应结构

/// 对应 GET /papers 的响应体：{ "papers": [...] }
private struct PapersResponse: Decodable {
    let papers: [Paper]
}

/// 对应 GET /papers/:id 的响应体：{ "paper": {...} }
private struct PaperResponse: Decodable {
    let paper: Paper
}

/// 对应 GET /news 的响应体：{ "news": [...] }
private struct NewsResponse: Decodable {
    let news: [NewsItem]
}

/// 对应 POST /auth/apple 的响应体：{ "token": "..." }
private struct SignInResponse: Decodable {
    let token: String
}

/// 对应 GET /favorites 的响应体
private struct FavoritesResponse: Decodable {
    struct FavoriteItem: Decodable {
        let paper: Paper?
    }
    let favorites: [FavoriteItem]
}

/// 通用计数响应
private struct CountResponse: Decodable {
    let count: Int
}

/// 我的页计数
struct ProfileCounts: Equatable {
    let downloadCount: Int
    let correctionCount: Int
    let studyRecordCount: Int
}

/// 会员状态
struct MembershipStatus: Decodable {
    let isMember: Bool
    let expiresAt: String?
    let isPermanent: Bool
}

/// 对应 POST /membership/apple/verify 的响应体
private struct VerifyPurchaseResponse: Decodable {
    let success: Bool
    let message: String?
}
