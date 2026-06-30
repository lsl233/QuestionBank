CREATE TABLE IF NOT EXISTS papers (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    year        VARCHAR(4) NOT NULL,
    region      VARCHAR(32) NOT NULL,
    subject     VARCHAR(16) NOT NULL,
    file_name   VARCHAR(255) NOT NULL UNIQUE,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_papers_filter ON papers(year, region, subject);

CREATE TABLE IF NOT EXISTS news (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tag         VARCHAR(16) NOT NULL,
    date        VARCHAR(5) NOT NULL,
    title       VARCHAR(255) NOT NULL UNIQUE,
    description TEXT NOT NULL,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);
