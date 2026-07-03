import 'dotenv/config';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { pool, query } from './index.js';
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const sampleNews = [
    {
        tag: '最新',
        date: '06-25',
        title: '2024 新高考 I 卷已全部上线',
        description: '语文、数学、英语、物理、化学、生物 6 科真题与答案已同步更新。',
    },
    {
        tag: '更新',
        date: '06-24',
        title: '上海卷 2024 真题已更新',
        description: '新增上海卷语文、数学、英语真题，支持在线阅读与下载。',
    },
    {
        tag: '最新',
        date: '06-23',
        title: '2024 全国甲卷理科数学上线',
        description: '全国甲卷理科数学真题与详细解析已同步更新。',
    },
];
// 会员产品配置，product_id 需与 App Store Connect 中配置的一致
const membershipProducts = [
    { appleProductId: 'com.lsl.QuestionBankApp.membership.month', name: '月度会员', durationDays: 30, isPermanent: false },
    { appleProductId: 'com.lsl.QuestionBankApp.membership.quarter', name: '季度会员', durationDays: 90, isPermanent: false },
    { appleProductId: 'com.lsl.QuestionBankApp.membership.year', name: '年度会员', durationDays: 365, isPermanent: false },
    { appleProductId: 'com.lsl.QuestionBankApp.membership.permanent', name: '永久会员', durationDays: null, isPermanent: true },
];
async function run() {
    const schemaPath = path.join(__dirname, 'schema.sql');
    const schema = await fs.readFile(schemaPath, 'utf-8');
    await query(schema);
    for (const product of membershipProducts) {
        await query(`INSERT INTO membership_products (apple_product_id, name, duration_days, is_permanent)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (apple_product_id) DO UPDATE SET
         name = EXCLUDED.name,
         duration_days = EXCLUDED.duration_days,
         is_permanent = EXCLUDED.is_permanent`, [product.appleProductId, product.name, product.durationDays, product.isPermanent]);
    }
    for (const news of sampleNews) {
        await query(`INSERT INTO news (tag, date, title, description)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (title) DO NOTHING`, [news.tag, news.date, news.title, news.description]);
    }
    // 创建固定测试账号，仅开发调试使用
    await query(`INSERT INTO users (apple_user_id, email, name)
     VALUES ($1, $2, $3)
     ON CONFLICT (apple_user_id) DO UPDATE SET
       email = EXCLUDED.email,
       name = EXCLUDED.name`, ['test-user', 'test@example.com', '测试用户']);
    console.log('Seed completed.');
    await pool.end();
}
run().catch((err) => {
    if (err instanceof Error) {
        console.error(err.message);
    }
    else {
        console.error(err);
    }
    process.exit(1);
});
