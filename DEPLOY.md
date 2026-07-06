# QuestionBank 部署操作文档

本文档描述如何将 QuestionBank 后端服务部署到腾讯云/阿里云等 Linux 服务器，并接入七牛云对象存储提供 PDF 下载。

## 一、部署前准备

### 1.1 需要购买的资源

| 资源 | 推荐配置 | 说明 |
|---|---|---|
| 云服务器 | 1 核 2G，Ubuntu 24.04 LTS | 最低 1 核 1G 也能跑，但建议 2G 内存 |
| 系统盘 | 40GB SSD | 代码、日志、数据库占用不大 |
| 对象存储 | 七牛云 Kodo | 存储 PDF 文件，按量付费 |
| 域名（可选） | 已备案域名 | 用于 HTTPS 和自定义 CDN 域名 |

### 1.2 需要记录的信息

部署过程中会生成或用到以下信息，建议提前准备：

- 服务器公网 IP、SSH 用户名、密码或私钥
- PostgreSQL 数据库名、用户名、密码
- 七牛云 AccessKey、SecretKey、Bucket 名称、公开域名
- Apple Sign In 的 Client ID（即 App Bundle ID）
- JWT 签名密钥（随机字符串）

---

## 二、服务器基础环境配置

### 2.1 连接服务器

```bash
ssh ubuntu@<服务器IP>
```

首次登录建议更新系统：

```bash
sudo apt-get update
sudo apt-get install -y curl wget gnupg ca-certificates build-essential software-properties-common git
```

### 2.2 创建 Swap（内存小于 2G 时必需）

```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
```

### 2.3 安装 Node.js 20

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pnpm pm2
```

验证安装：

```bash
node -v    # v20.x
pnpm -v    # 10.x
pm2 -v     # 7.x
```

### 2.4 安装 PostgreSQL

```bash
sudo apt-get install -y postgresql postgresql-contrib
```

低内存服务器需要限制 PostgreSQL 内存占用：

```bash
sudo tee /etc/postgresql/16/main/conf.d/low-memory.conf > /dev/null <<EOF
shared_buffers = 64MB
effective_cache_size = 256MB
work_mem = 4MB
maintenance_work_mem = 32MB
max_connections = 50
listen_addresses = 'localhost'
EOF

sudo systemctl restart postgresql
```

### 2.5 安装 Nginx

```bash
sudo apt-get install -y nginx
```

---

## 三、数据库初始化

### 3.1 创建数据库和用户

```bash
DB_NAME="questionbank"
DB_USER="questionbank"
DB_PASS="<随机生成强密码>"

sudo -u postgres psql <<EOF
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DB_USER') THEN
    CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';
  ELSE
    ALTER USER $DB_USER WITH PASSWORD '$DB_PASS';
  END IF;
END
\$\$;

SELECT 'CREATE DATABASE $DB_NAME OWNER $DB_USER'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME')\gexec

GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOF
```

### 3.2 拉取代码并安装依赖

```bash
cd /home/ubuntu
git clone https://github.com/lsl233/QuestionBank.git questionbank
cd questionbank/QuestionBankServer
pnpm install
```

### 3.3 执行数据库 Schema 和 Seed

```bash
# 设置环境变量（临时）
export DATABASE_URL="postgresql://$DB_USER:$DB_PASS@localhost:5432/$DB_NAME"

# 执行 schema
sudo -u postgres psql -d "$DB_NAME" -f src/db/schema.sql

# 执行 seed（插入示例新闻、会员产品、测试账号）
pnpm exec tsx src/db/seed.ts
```

---

## 四、环境变量配置

在 `QuestionBankServer/` 目录下创建 `.env` 文件：

```env
DATABASE_URL=postgresql://questionbank:<密码>@localhost:5432/questionbank
PORT=3000
FILES_DIR=./files
JWT_SECRET=<随机生成 64 位十六进制字符串>
APPLE_CLIENT_ID=name.lsl.QuestionBankApp
APPLE_IAP_ENV=sandbox
APPLE_ROOT_CA_DIR=./certs
APPLE_IAP_SKIP_VERIFY=false
ENABLE_TEST_AUTH=false

# 七牛云配置
QINIU_ENABLED=true
QINIU_ACCESS_KEY=<七牛云 AccessKey>
QINIU_SECRET_KEY=<七牛云 SecretKey>
QINIU_BUCKET=question-bank-files
QINIU_PUBLIC_DOMAIN=http://<七牛云域名>
QINIU_PRIVATE_URL_EXPIRES=3600
```

说明：

- `QINIU_ENABLED=false` 时，后端会从本地 `FILES_DIR` 直传 PDF，方便开发测试。
- `QINIU_ENABLED=true` 时，后端校验权限后返回 302 重定向到七牛私有空间的临时签名 URL，PDF 流量不走服务器。
- `QINIU_PRIVATE_URL_EXPIRES` 为签名 URL 有效期，单位秒，默认 3600。

```bash
openssl rand -hex 32
```

---

## 五、七牛云对象存储配置

### 5.1 创建 Bucket

1. 登录七牛云控制台 → 对象存储 Kodo
2. 创建空间，名称如 `question-bank-files`
3. 访问控制选择**私有**
4. 记录分配的测试域名或绑定自定义域名

### 5.2 获取密钥

1. 控制台 → 个人中心 → 密钥管理
2. 复制 AccessKey 和 SecretKey
3. **建议创建子账号密钥，只授权访问该 Bucket**

### 5.3 配置防盗链（重要）

1. 进入 Bucket → 空间设置 → 防盗链
2. **关闭 Referer 防盗链**，或
3. 开启防盗链并勾选**允许空 Referer 访问**（iOS App 不会带 Referer）

### 5.4 临时签名 URL 说明

App 请求后端 `/files/:name` 或 `/files/:name/preview` 时：

1. 后端先校验权限（预览公开，下载需会员）。
2. 后端用七牛私有 Bucket 的密钥签发临时下载 URL，有效期由 `QINIU_PRIVATE_URL_EXPIRES` 控制。
3. 后端返回 302 重定向到该临时 URL，App 自动跟随并下载 PDF。

因此 PDF 实际流量走七牛 CDN，不经过服务器。

### 5.5 上传 PDF 文件

本地 PDF 文件应放在 `QuestionBankServer/files/` 目录下，结构示例：

```
files/
├── 2026上海.pdf
├── 1954_数学_普通高考/
│   └── 试卷/
│       └── 1954_数学_普通高考_试卷.pdf
└── 2002_数学_普通高考_上海卷_理/
    └── 试卷/
        └── 2002_数学_普通高考_上海卷_理_试卷.pdf
```

使用七牛云 qshell 或 SDK 按原目录结构上传到 Bucket。上传后七牛云上的文件 key 就是相对路径，例如：

```
2026上海.pdf
1954_数学_普通高考/试卷/1954_数学_普通高考_试卷.pdf
```

---

## 六、同步数据库记录

上传 PDF 后，需要往 `papers` 和 `paper_files` 表插入记录。

### 6.1 papers 表字段

| 字段 | 说明 | 示例 |
|---|---|---|
| year | 年份 | 2024 |
| exam_type | 考试类型 | 普通高考 / 春季高考 |
| region | 地区/卷别 | 北京卷 / 全国I卷 |
| subject | 科目 | 数学 |
| stream | 文/理（可选） | 文 / 理 |
| file_name | 唯一标识 | 2024-beijing-math |
| title | 展示标题 | 2024·北京卷·数学 |

### 6.2 paper_files 表字段

| 字段 | 说明 | 示例 |
|---|---|---|
| paper_id | 关联 papers.id | uuid |
| file_type | 文件类型 | exam_paper |
| file_path | 七牛云 key | papers/2024/beijing-math.pdf |
| mime_type | MIME 类型 | application/pdf |

### 6.3 插入示例

```sql
INSERT INTO papers (year, exam_type, region, subject, stream, file_name, title)
VALUES ('2024', '普通高考', '北京卷', '数学', NULL, '2024-beijing-math', '2024·北京卷·数学');

INSERT INTO paper_files (paper_id, file_type, file_path, mime_type)
VALUES (
  (SELECT id FROM papers WHERE file_name = '2024-beijing-math'),
  'exam_paper',
  'papers/2024/beijing-math.pdf',
  'application/pdf'
);
```

---

## 七、构建并启动后端

### 7.1 构建

```bash
cd /home/ubuntu/questionbank/QuestionBankServer
pnpm run build
```

### 7.2 配置 Nginx 反向代理

创建 `/etc/nginx/sites-available/questionbank`：

```nginx
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    client_max_body_size 50M;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

启用配置：

```bash
sudo rm -f /etc/nginx/sites-enabled/default
sudo ln -sf /etc/nginx/sites-available/questionbank /etc/nginx/sites-enabled/questionbank
sudo nginx -t
sudo systemctl restart nginx
```

### 7.3 PM2 启动

```bash
cd /home/ubuntu/questionbank/QuestionBankServer
pm2 start dist/index.js --name questionbank-server
pm2 save
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu
```

常用命令：

```bash
pm2 status                    # 查看状态
pm2 logs questionbank-server  # 查看日志
pm2 restart questionbank-server --update-env  # 重启并更新环境变量
```

---

## 八、iOS App 配置

### 8.1 修改 API 地址

编辑 `QuestionBankApp/Core/Network/APIService.swift`：

```swift
static let baseURL = "http://<服务器公网IP>"
```

### 8.2 配置 ATS 允许 HTTP

编辑 `QuestionBankApp/Info.plist`，在 `NSAppTransportSecurity` 下添加例外域名：

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
    <key>NSExceptionDomains</key>
    <dict>
        <key><服务器IP></key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
        <key><七牛云域名></key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

### 8.3 上线前建议

- 购买备案域名
- 服务器配置 HTTPS（Let's Encrypt 免费证书）
- 七牛云绑定 HTTPS 域名
- 移除 ATS HTTP 例外

---

## 九、验证部署

### 9.1 测试后端接口

```bash
# 测试新闻接口
curl http://<服务器IP>/news

# 测试试卷列表
curl http://<服务器IP>/papers?limit=3

# 测试 PDF 预览重定向：应返回 302，Location 为七牛临时签名 URL
curl -I "http://<服务器IP>/files/<file_name>/preview"

# 测试会员下载重定向：需携带登录 token，应返回 302
curl -I "http://<服务器IP>/files/<file_name>" -H "Authorization: Bearer <token>"
```

### 9.2 检查服务状态

```bash
# 服务器端
pm2 status
sudo systemctl status nginx
sudo systemctl status postgresql

# 检查端口
ss -tlnp | grep -E '3000|80'
```

---

## 十、常见问题

### Q1: App 提示 "The resource could not be loaded because ATS policy..."

A: 在 `Info.plist` 中添加 ATS 例外，或尽快切换到 HTTPS。

### Q2: PDF 下载返回 403 / referer forbidden

A: 七牛云防盗链限制。进入七牛云控制台关闭防盗链，或允许空 Referer。

### Q3: `/papers/:id/view` 404

A: 确保后端 `src/routes/papers.ts` 包含 `POST /:id/view` 路由。如果代码较旧，请拉取最新代码或手动添加。

### Q4: 服务器内存不足导致服务崩溃

A: 增加 Swap，或升级服务器到 2G 内存。同时检查 PostgreSQL 内存限制配置。

### Q5: 如何更新后端代码？

```bash
cd /home/ubuntu/questionbank
git pull
pnpm install
pnpm run build
pm2 restart questionbank-server --update-env
```

---

## 十一、文件变更清单

部署过程中会修改或生成的文件：

- `QuestionBankServer/.env` —— 环境变量（服务器上生成，**不要提交到 Git**）
- `QuestionBankServer/src/routes/files.ts` —— 七牛云重定向逻辑
- `QuestionBankServer/src/config/env.ts` —— 七牛云环境变量声明
- `QuestionBankApp/Info.plist` —— ATS 例外配置
- `QuestionBankApp/Core/Network/APIService.swift` —— API baseURL
