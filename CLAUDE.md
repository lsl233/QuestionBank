# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

本工作空间包含两个子项目：

- `QuestionBankApp/` —— 用于浏览和查看高考 PDF 试卷的 SwiftUI iOS 应用。
- `QuestionBankServer/` —— 基于 Hono/TypeScript 的后端服务，使用 PostgreSQL 存储试卷和新闻数据，通过本地文件目录提供 PDF 下载。

## 产品定位

- **产品**：高考试题小应用。
- **目标用户**：高中学生，以及想要练习往届高考考试内容的学生。
- **盈利模式**：PDF 下载收费；未来可能扩展实物打印服务。

## QuestionBankApp（iOS）

- **平台**：iOS 26.0+
- **语言**：Swift 5
- **UI 框架**：SwiftUI
- **Bundle 标识符**：`name.lsl.QuestionBankApp`
- **无外部包依赖**（仅使用 PDFKit 和系统框架）

### 常用命令

在 iOS 模拟器中构建应用：

```bash
xcodebuild -project QuestionBankApp/QuestionBankApp.xcodeproj -scheme QuestionBankApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
```

运行单元测试（使用 Swift Testing）：

```bash
xcodebuild -project QuestionBankApp/QuestionBankApp.xcodeproj -scheme QuestionBankApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

运行单个单元测试：

```bash
xcodebuild -project QuestionBankApp/QuestionBankApp.xcodeproj -scheme QuestionBankApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test -only-testing QuestionBankAppTests/QuestionBankAppTests/example
```

运行 UI 测试：

```bash
xcodebuild -project QuestionBankApp/QuestionBankApp.xcodeproj -scheme QuestionBankApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test -only-testing QuestionBankAppUITests
```

列出可用的模拟器目标：

```bash
xcodebuild -project QuestionBankApp/QuestionBankApp.xcodeproj -scheme QuestionBankApp -destination 'platform=iOS Simulator' -showdestinations
```

### 架构

应用使用单个 `WindowGroup`，根视图为 `HomeView`。目录按 **Feature-Based** 组织，跨功能共享的模型、网络层和通用 UI 组件放在 `Core/` 中。

- `QuestionBankApp/QuestionBankApp/QuestionBankAppApp.swift` —— 应用入口，将 `HomeView()` 设为根视图。
- `QuestionBankApp/QuestionBankApp/Core/Network/APIService.swift` —— 网络请求封装，负责调用后端 `/papers`、`/news`、`/files/:name` 接口，并提供 `downloadPDF(fileName:)` 将 PDF 保存到应用沙盒。
- `QuestionBankApp/QuestionBankApp/Core/Models/Paper.swift` —— 高考试卷数据模型（`Codable`），包含年份/地区/科目筛选项。
- `QuestionBankApp/QuestionBankApp/Core/Models/NewsItem.swift` —— 新闻公告数据模型（`Codable`）。
- `QuestionBankApp/QuestionBankApp/Core/UIComponents/` —— 通用 UI 组件：`SearchBarView`、`FilterSectionView`、`ShareSheet`。
- `QuestionBankApp/QuestionBankApp/Core/Theme/Color+Theme.swift` —— 主题色扩展，定义 `Color.brandCinnabar`、`Color.warmCream`、`Color.darkBrown` 等。
- `QuestionBankApp/QuestionBankApp/Core/Theme/AppTheme.swift` —— 语义化配色命名空间，业务代码优先使用 `AppTheme.accent`、`AppTheme.background` 等。
- `QuestionBankApp/QuestionBankApp/Core/Theme/Font+Theme.swift` —— 自定义字体扩展：`Font.serifChinese(...)`（Source Han Serif CN）和 `Font.monoEnglish(...)`（Space Mono）。
- `QuestionBankApp/QuestionBankApp/Features/Home/HomeView.swift` —— 主页面，进入时拉取试卷列表和新闻公告，组装 `HeaderView`、`HeroCardView`、`SearchBarView`、`FilterSectionView`、`NewsSectionView`、`PaperListSectionView`。
- `QuestionBankApp/QuestionBankApp/Features/Home/Components/HeaderView.swift` —— 首页顶部双语标题区。
- `QuestionBankApp/QuestionBankApp/Features/Home/Views/HeroCardView.swift` —— 深色高考倒计时 Hero 卡片。
- `QuestionBankApp/QuestionBankApp/Features/Papers/PaperDetailView.swift` —— 试卷详情页，进入后自动下载 PDF 到 `Documents` 再本地渲染；底部工具栏提供收藏、下载/分享、勘误反馈入口。
- `QuestionBankApp/QuestionBankApp/Features/Papers/Views/` —— 试卷相关视图：`PaperListSectionView`、`PDFViewer`。
- `QuestionBankApp/QuestionBankApp/Features/Papers/Components/PaperRowView.swift` —— 单条试卷行。
- `QuestionBankApp/QuestionBankApp/Features/News/Views/NewsSectionView.swift` —— 最新动态区块。
- `QuestionBankApp/QuestionBankApp/Features/News/Components/NewsCardView.swift` —— 单张动态卡片。
- `QuestionBankApp/QuestionBankApp/Resources/Fonts/` —— 自定义字体文件（当前包含 `SpaceMono-Regular.ttf`）。
- `QuestionBankApp/Info.plist` —— 自定义 plist，配置 `NSAllowsLocalNetworking` 允许开发时访问 `http://localhost:3000`，并注册 `UIAppFonts`。

筛选和搜索在 `HomeView.filteredPapers` 中本地计算，搜索框与年份/地区/科目筛选器已在首页启用。

测试分为两个目标：

- `QuestionBankAppTests` —— Swift Testing 单元测试。
- `QuestionBankAppUITests` —— XCTest UI 测试。

## QuestionBankServer（后端）

- **运行时**：Node.js，ES 模块（`"type": "module"`）
- **框架**：Hono 4.x，配合 `@hono/node-server`
- **数据库**：PostgreSQL，使用 `pg` 原生驱动（无 ORM）
- **校验**：Zod
- **语言**：TypeScript 5.8，启用严格模式，使用 NodeNext 模块解析策略
- **PDF 存储**：本地 `files/` 目录，通过 `/files/:name` 接口直传

### 环境变量

后端依赖 `QuestionBankServer/.env`：

```env
DATABASE_URL=postgresql://user:pass@host:5432/questionbank
PORT=3000
FILES_DIR=./files
```

### 常用命令

安装依赖：

```bash
cd QuestionBankServer
pnpm install
```

初始化数据库（创建表并写入示例数据）：

```bash
pnpm db:seed
```

启动开发服务器：

```bash
pnpm run dev
```

构建并启动生产服务器：

```bash
pnpm run build
pnpm start
```

开发服务器运行在 `http://localhost:3000`。

### 接口

| 方法 | 路径 | 说明 |
|---|---|---|
| GET | `/papers?year=&region=&subject=&search=` | 试卷列表，支持年份/地区/科目筛选和文件名搜索 |
| GET | `/papers/:id` | 试卷详情 |
| GET | `/news` | 新闻公告列表 |
| GET | `/files/:name` | PDF 下载（`name` 不含 `.pdf` 后缀） |

### 架构

- `QuestionBankServer/src/index.ts` —— 入口文件。加载环境变量，挂载 `/papers`、`/news`、`/files` 路由，启动服务器。
- `QuestionBankServer/src/config/env.ts` —— 使用 Zod 解析和校验 `DATABASE_URL`、`PORT`、`FILES_DIR`。
- `QuestionBankServer/src/db/index.ts` —— `pg.Pool` 单例与 `query<T>` 辅助函数。
- `QuestionBankServer/src/db/schema.sql` —— `papers` 和 `news` 表的 DDL。
- `QuestionBankServer/src/db/seed.ts` —— 初始化数据脚本，写入示例试卷与新闻。
- `QuestionBankServer/src/routes/papers.ts` —— 试卷列表与详情接口。
- `QuestionBankServer/src/routes/news.ts` —— 新闻公告列表接口。
- `QuestionBankServer/src/routes/files.ts` —— PDF 文件下载接口，带路径遍历防护。

### 开发注意

- `files/` 目录与 `.env` 已加入 `.gitignore`，不要提交 PDF 和数据库凭证。
- `Content-Disposition` 中的中文文件名使用 `filename*=UTF-8''` 编码，避免 Node.js 报非法字符错误。
- seed 脚本可重复执行，`papers` 按 `file_name` 去重，`news` 按 `title` 去重。

## 跨项目说明

- iOS 应用已接入 `QuestionBankServer`：首页从后端拉取试卷列表和新闻公告，试卷详情页进入后自动下载 PDF 到本地 `Documents`，再用本地文件渲染和分享。
- 后端服务提供试卷列表、详情、新闻公告和 PDF 下载接口；本地开发时 iOS 通过 `http://localhost:3000` 访问，真机测试需把 `APIService.APIConfig.baseURL` 改为电脑局域网 IP。
