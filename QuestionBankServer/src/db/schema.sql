-- 会员模块依赖的表需要后于被依赖表删除
DROP TABLE IF EXISTS favorites;
DROP TABLE IF EXISTS paper_files;
DROP TABLE IF EXISTS user_memberships;
DROP TABLE IF EXISTS apple_transactions;
DROP TABLE IF EXISTS membership_products;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS papers;
DROP TABLE IF EXISTS news;

-- 高考试卷主表：一份逻辑试卷对应一行
CREATE TABLE IF NOT EXISTS papers (
    -- 唯一标识
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 年份，如 2025
    year        VARCHAR(4) NOT NULL,
    -- 考试类型：普通高考 / 春季高考
    exam_type   VARCHAR(16) NOT NULL DEFAULT '普通高考',
    -- 地区/卷别，如 北京卷、新高考I卷
    region      VARCHAR(64) NOT NULL,
    -- 科目，如 数学
    subject     VARCHAR(16) NOT NULL,
    -- 文/理分科，旧课程试卷使用
    stream      VARCHAR(8),
    -- 额外备注，如 旧课程、初试、省份列表
    note        VARCHAR(64),
    -- 主试卷文件的无扩展名文件名，也是 /files/:name 的查询键
    file_name   VARCHAR(255) NOT NULL UNIQUE,
    -- 展示标题，如 2025·北京卷·数学
    title       VARCHAR(255) NOT NULL,
    -- 查看次数
    view_count  INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_papers_filter ON papers(year, exam_type, region, subject, stream);

-- 试卷文件表：一份试卷可关联多个文件类型（试卷、答案、解析、听力等）
CREATE TABLE IF NOT EXISTS paper_files (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 关联 papers.id，试卷删除时级联删除文件记录
    paper_id    UUID NOT NULL REFERENCES papers(id) ON DELETE CASCADE,
    -- 文件类型枚举
    file_type   VARCHAR(16) NOT NULL CHECK (file_type IN (
        'exam_paper',
        'answer',
        'analysis',
        'listening_audio',
        'listening_text',
        'ocr_text',
        'markdown'
    )),
    -- 相对于 FILES_DIR 的存储路径，便于未来迁移到 OSS
    file_path   VARCHAR(512) NOT NULL,
    -- MIME 类型，用于下载响应头
    mime_type   VARCHAR(64),
    -- 文件大小（字节）
    size_bytes  BIGINT,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    -- 同一试卷同一类型只能有一个文件
    UNIQUE (paper_id, file_type)
);

CREATE INDEX IF NOT EXISTS idx_paper_files_paper ON paper_files(paper_id);

-- 用户表：支持 Apple 登录和后续邮箱密码登录
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- Apple 登录唯一标识
    apple_user_id   VARCHAR(255) UNIQUE,
    -- 邮箱，可用于邮箱密码登录及接收通知
    email           VARCHAR(255) UNIQUE,
    -- 密码哈希（bcrypt），邮箱登录时使用
    password_hash   VARCHAR(255),
    -- 用户昵称
    name            VARCHAR(128),
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    -- 至少有一种登录方式
    CHECK (apple_user_id IS NOT NULL OR password_hash IS NOT NULL)
);

-- 会员产品配置表：映射 Apple IAP 产品 ID 到会员时长
CREATE TABLE IF NOT EXISTS membership_products (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- App Store Connect 产品 ID，如 name.lsl.QuestionBankApp.membership.month
    apple_product_id VARCHAR(255) NOT NULL UNIQUE,
    -- 展示名称，如 月度会员
    name             VARCHAR(64) NOT NULL,
    -- 会员有效天数；NULL 表示永久
    duration_days    INTEGER,
    -- 是否为永久会员
    is_permanent     BOOLEAN NOT NULL DEFAULT false,
    created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- 用户会员状态表：每个用户一行，记录当前是否会员及过期时间
CREATE TABLE IF NOT EXISTS user_memberships (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 关联 users.id
    user_id         UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    -- 当前是否有效会员
    is_active       BOOLEAN NOT NULL DEFAULT false,
    -- 到期时间；永久会员可存 9999-12-31
    expires_at      TIMESTAMPTZ,
    -- 最近一次购买的产品
    last_product_id UUID REFERENCES membership_products(id),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_memberships_user ON user_memberships(user_id);

-- Apple 交易流水表：保存每笔已校验的 StoreKit 2 交易，用于幂等和审计
CREATE TABLE IF NOT EXISTS apple_transactions (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 购买用户
    user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- 对应 membership_products.id
    product_id              UUID NOT NULL REFERENCES membership_products(id),
    -- Apple transactionId，唯一防止重复累加时长
    transaction_id          VARCHAR(255) NOT NULL UNIQUE,
    -- Apple originalTransactionId
    original_transaction_id VARCHAR(255) NOT NULL,
    -- StoreKit 2 原始 JWS
    signed_transaction_jws  TEXT NOT NULL,
    -- 交易时间
    purchased_at            TIMESTAMPTZ NOT NULL,
    -- 订阅到期时间（一次性购买可空）
    expires_at              TIMESTAMPTZ,
    -- Apple 退款/撤销时间
    revoked_at              TIMESTAMPTZ,
    created_at              TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_apple_transactions_user ON apple_transactions(user_id);

-- 用户收藏表
CREATE TABLE IF NOT EXISTS favorites (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- 收藏者
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- 被收藏试卷
    paper_id   UUID NOT NULL REFERENCES papers(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, paper_id)
);

CREATE INDEX IF NOT EXISTS idx_favorites_user ON favorites(user_id);

-- 下载历史表
CREATE TABLE IF NOT EXISTS downloads (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    paper_id   UUID NOT NULL REFERENCES papers(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, paper_id)
);

CREATE INDEX IF NOT EXISTS idx_downloads_user ON downloads(user_id, created_at DESC);

-- 勘误反馈表
CREATE TABLE IF NOT EXISTS corrections (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    paper_id   UUID NOT NULL REFERENCES papers(id) ON DELETE CASCADE,
    content    TEXT NOT NULL,
    status     VARCHAR(16) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','resolved','ignored')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_corrections_user ON corrections(user_id, created_at DESC);

-- 学习记录表
CREATE TABLE IF NOT EXISTS study_records (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    paper_id     UUID NOT NULL REFERENCES papers(id) ON DELETE CASCADE,
    viewed_at    TIMESTAMPTZ DEFAULT NOW(),
    duration_sec INTEGER DEFAULT 0,
    UNIQUE (user_id, paper_id)
);

CREATE INDEX IF NOT EXISTS idx_study_records_user ON study_records(user_id, viewed_at DESC);

-- 新闻公告表
CREATE TABLE IF NOT EXISTS news (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tag         VARCHAR(16) NOT NULL,
    date        VARCHAR(5) NOT NULL,
    title       VARCHAR(255) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);
