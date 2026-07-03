import { Hono } from 'hono'

export const privacyRouter = new Hono()

const privacyHtml = `<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>隐私政策 - 历届真题库</title>
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      line-height: 1.7;
      color: #1a1a1a;
      background: #fafafa;
      margin: 0;
      padding: 16px;
    }
    .container {
      max-width: 720px;
      margin: 0 auto;
      background: #fff;
      padding: 32px 24px;
      border-radius: 12px;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
    }
    h1 {
      font-size: 26px;
      margin: 0 0 8px;
      color: #b92b27;
    }
    .updated {
      font-size: 14px;
      color: #666;
      margin-bottom: 28px;
    }
    h2 {
      font-size: 18px;
      margin: 28px 0 12px;
      color: #333;
    }
    p {
      margin: 12px 0;
      font-size: 15px;
    }
    ul {
      padding-left: 22px;
      margin: 12px 0;
    }
    li {
      margin: 8px 0;
      font-size: 15px;
    }
    strong {
      color: #222;
    }
    a {
      color: #b92b27;
      text-decoration: none;
    }
    @media (max-width: 480px) {
      .container { padding: 24px 18px; }
      h1 { font-size: 22px; }
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>隐私政策</h1>
    <p class="updated">最后更新日期：2026年7月3日</p>

    <p>欢迎使用「历届真题库」。我们非常重视您的个人信息和隐私保护。本政策将帮助您了解我们如何处理您的个人信息。</p>

    <h2>1. 我们收集的信息</h2>
    <p>当您使用本应用时，我们可能收集以下信息：</p>
    <ul>
      <li><strong>Apple 用户标识符</strong>：通过 Apple「使用 Apple 登录」功能获取，用于创建和识别您的账号。</li>
      <li><strong>收藏与下载记录</strong>：您收藏的试卷、下载的试卷记录。</li>
      <li><strong>学习记录</strong>：您查看试卷的时长和进度记录。</li>
      <li><strong>勘误反馈</strong>：您提交的试卷错误反馈内容。</li>
      <li><strong>交易信息</strong>：通过 Apple 应用内购买产生的交易凭证，用于激活会员服务。</li>
    </ul>

    <h2>2. 信息的使用</h2>
    <p>我们使用收集的信息来：</p>
    <ul>
      <li>为您提供账号登录与数据同步服务；</li>
      <li>记录您的收藏、下载和学习进度；</li>
      <li>处理会员购买和续期；</li>
      <li>响应您提交的勘误反馈。</li>
    </ul>

    <h2>3. 信息的共享</h2>
    <p>我们不会将您的个人信息出售给第三方。仅在以下情况下可能共享数据：</p>
    <ul>
      <li>应法律法规或政府部门要求；</li>
      <li>与 Apple 处理应用内购买交易相关。</li>
    </ul>

    <h2>4. 数据的存储与安全</h2>
    <p>您的数据存储在我们的服务器中，我们采取合理的安全措施保护数据。认证令牌和个人标识符均经过加密处理，传输过程使用 HTTPS。</p>

    <h2>5. 您的权利</h2>
    <p>您可以随时在应用「我的」页面中选择「删除账号」，永久删除您的账号及所有关联数据。删除后，您的收藏、下载记录、学习记录、勘误反馈和会员状态将全部清除且不可恢复。</p>

    <h2>6. 联系我们</h2>
    <p>如有任何关于隐私政策的问题，请通过 App Store 页面中的开发者联系方式与我们联系。</p>
  </div>
</body>
</html>`

privacyRouter.get('/', (c) => {
  return c.html(privacyHtml)
})
