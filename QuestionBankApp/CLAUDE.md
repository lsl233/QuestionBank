# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

QuestionBankApp 是一个用于浏览和查看高考 PDF 试卷的 SwiftUI iOS 应用。仅使用系统框架（SwiftUI、PDFKit），无外部包依赖。

- **平台**：iOS 26.0+
- **语言**：Swift 5
- **UI 框架**：SwiftUI
- **Bundle 标识符**：`name.lsl.QuestionBankApp`

## 产品定位

- **目标用户**：高中学生，以及想要练习往届高考考试内容的学生。
- **盈利模式**：PDF 下载收费；未来可能扩展实物打印服务。

## 常用命令

在 iOS 模拟器中构建应用：

```bash
xcodebuild -project QuestionBankApp.xcodeproj -scheme QuestionBankApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

运行单元测试（使用 Swift Testing）：

```bash
xcodebuild -project QuestionBankApp.xcodeproj -scheme QuestionBankApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

运行单个单元测试：

```bash
xcodebuild -project QuestionBankApp.xcodeproj -scheme QuestionBankApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test -only-testing QuestionBankAppTests/QuestionBankAppTests/example
```

运行 UI 测试：

```bash
xcodebuild -project QuestionBankApp.xcodeproj -scheme QuestionBankApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test -only-testing QuestionBankAppUITests
```

列出可用的模拟器目标：

```bash
xcodebuild -project QuestionBankApp.xcodeproj -scheme QuestionBankApp -destination 'platform=iOS Simulator' -showdestinations
```

## 架构

应用遵循标准 SwiftUI 应用生命周期，使用单个 `WindowGroup`。目录按 **Feature-Based** 组织，跨功能共享的模型、网络层和通用 UI 组件放在 `Core/` 中。

- `QuestionBankApp/QuestionBankAppApp.swift` —— 应用入口，创建包含「首页 / 题库 / 收藏 / 我的」的 `TabView`，注入 `AuthManager`、`UserDataStore`、`TabRouter`。
- `QuestionBankApp/Core/Router/TabRouter.swift` —— 底部 Tab 选中状态管理，支持跨 Tab 跳转。
- `QuestionBankApp/Core/Network/APIService.swift` —— 网络请求封装，负责调用后端 `/papers`、`/news`、`/files/:name` 接口，并提供 `downloadPDF(fileName:)` 将 PDF 保存到应用沙盒。
- `QuestionBankApp/Core/Models/Paper.swift` —— 高考试卷数据模型（`Codable`），包含年份/地区/科目筛选项与 `createdAt`（创建时间）。
- `QuestionBankApp/Core/Models/NewsItem.swift` —— 新闻公告数据模型（`Codable`）。
- `QuestionBankApp/Core/UIComponents/` —— 通用 UI 组件：`SearchBarView`、`FilterSectionView`、`ShareSheet`、`AsyncListContainerView`、`LoginGuardView`、`LoginPromptView`。
- `QuestionBankApp/Core/Theme/Color+Theme.swift` —— 主题色扩展，定义 `Color.brandCinnabar`、`Color.warmCream`、`Color.darkBrown` 等。
- `QuestionBankApp/Core/Theme/AppTheme.swift` —— 语义化配色命名空间，业务代码优先使用 `AppTheme.accent`、`AppTheme.background` 等。
- `QuestionBankApp/Core/Theme/Font+Theme.swift` —— 自定义字体扩展：`Font.serifChinese(...)`（Source Han Serif CN）和 `Font.monoEnglish(...)`（Space Mono）。
- `QuestionBankApp/Features/Home/HomeView.swift` —— 主页面，进入时从后端拉取新闻公告与最新试卷，组装 `HeaderView`、`NewsSectionView`、`LatestQuestionsModule`、`FavoritesModule`（登录且有收藏时显示）。
- `QuestionBankApp/Features/Home/Components/HeaderView.swift` —— 首页顶部双语标题区。
- `QuestionBankApp/Features/Papers/PapersView.swift` —— 题库 Tab，使用 `LoginGuardView` + `AsyncListContainerView` 控制状态，支持搜索与年份/地区/科目筛选。
- `QuestionBankApp/Features/Papers/PapersViewModel.swift` —— 题库浏览状态与本地过滤逻辑。
- `QuestionBankApp/Features/Papers/PaperDetailView.swift` —— 试卷详情页，进入后自动下载 PDF 到 `Documents` 再本地渲染；底部工具栏提供收藏、下载/分享、勘误反馈入口。
- `QuestionBankApp/Features/Papers/Views/` —— 试卷相关视图：`PaperListSectionView`、`PDFViewer`。
- `QuestionBankApp/Features/Papers/Components/` —— 试卷相关组件：`PaperRowView`（内容卡片）、`PaperRowCell`（可点击行 + 收藏星标）、`FavoriteStarButton`。
- `QuestionBankApp/Features/Favorites/FavoritesView.swift` —— 收藏 Tab，展示当前用户收藏的试卷。
- `QuestionBankApp/Features/Profile/ProfileView.swift` —— 我的页面。
- `QuestionBankApp/Features/News/Views/NewsSectionView.swift` —— 最新动态区块。
- `QuestionBankApp/Features/News/Components/NewsCardView.swift` —— 单张动态卡片。
- `QuestionBankApp/Resources/Fonts/` —— 自定义字体文件（当前包含 `SpaceMono-Regular.ttf`）。

PDF 不再从主 bundle 加载，而是通过 `APIService.downloadPDF(fileName:)` 从后端 `GET /files/:name` 下载到应用沙盒的 `Documents` 目录，再本地渲染和分享。

底部 Tab 结构为「首页 / 题库 / 收藏 / 我的」。首页展示新闻公告、最新 3 套试题（带创建时间、无收藏按钮）以及登录用户的收藏入口；题库 Tab 提供搜索与年份/地区/科目筛选，使用 `PapersViewModel` 本地过滤。

测试分为两个目标：

- `QuestionBankAppTests` —— Swift Testing 单元测试。
- `QuestionBankAppUITests` —— XCTest UI 测试。
