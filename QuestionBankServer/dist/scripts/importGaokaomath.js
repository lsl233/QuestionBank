import 'dotenv/config';
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { pool, query } from '../db/index.js';
import { env } from '../config/env.js';
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SOURCE_DIR = '/Users/xxx/Documents/gaokaomath';
const SUBJECT = '数学';
// 文件类型与数据库枚举的映射（目前只处理试卷 PDF）
const FILE_TYPE = 'exam_paper';
const FILE_TYPE_FOLDER = '试卷';
const examTypeByFolder = {
    '普通高考': '普通高考',
    '春季高考': '春季高考',
};
const regionReplacements = [
    [/^新高考1$/, '新高考I卷'],
    [/^新高考2$/, '新高考II卷'],
    [/^全国甲$/, '全国甲卷'],
    [/^全国乙$/, '全国乙卷'],
    [/^全国1$/, '全国I卷'],
    [/^全国2$/, '全国II卷'],
    [/^全国3$/, '全国III卷'],
    [/^全国4$/, '全国IV卷'],
    [/^(北京|上海|天津|重庆|浙江|江苏|山东|广东|湖南|湖北|河北|福建|安徽|江西|河南|四川|陕西|山西|辽宁|吉林|黑龙江|广西|贵州|云南|甘肃|青海|海南|宁夏|新疆|内蒙古|西藏)$/, '$1卷'],
];
const streamSet = new Set(['文', '理']);
const noteKeywords = ['旧课程', '初试', '复试', '预考'];
function normalizeRegion(raw) {
    let region = raw;
    for (const [regex, replacement] of regionReplacements) {
        if (regex.test(region)) {
            region = region.replace(regex, replacement);
            break;
        }
    }
    return region;
}
function parseFileName(fileName, parentExamType, parentDirParts) {
    const base = path.basename(fileName, path.extname(fileName));
    // 1. 提取年份（前 4 位数字）
    const yearMatch = base.match(/^(\d{4})/);
    const year = yearMatch ? yearMatch[1] : 'unknown';
    let rest = yearMatch ? base.slice(yearMatch[0].length) : base;
    // 2. 提取括号内备注
    let note;
    const parenMatch = rest.match(/\(([^)]+)\)$/);
    if (parenMatch) {
        note = parenMatch[1];
        rest = rest.slice(0, parenMatch.index);
    }
    // 3. 如果没有括号备注，检查末尾是否包含已知备注关键词
    if (!note) {
        for (const keyword of noteKeywords) {
            if (rest.endsWith(keyword)) {
                note = keyword;
                rest = rest.slice(0, -keyword.length);
                break;
            }
        }
    }
    // 4. 检查目录层级是否包含 “初试/复试” 等备注
    if (!note) {
        const dirNote = parentDirParts.find((part) => noteKeywords.includes(part));
        if (dirNote)
            note = dirNote;
    }
    // 5. 春季高考文件名常以 “春季” 开头，已在目录中体现考试类型，此处剥离避免地区冗余
    if (parentExamType === '春季高考' && rest.startsWith('春季')) {
        rest = rest.slice(2);
    }
    // 6. 提取文/理分科
    let stream;
    if (streamSet.has(rest.slice(-1))) {
        stream = rest.slice(-1);
        rest = rest.slice(0, -1);
    }
    // 7. 剩余部分作为地区/卷别
    const region = normalizeRegion(rest);
    // 8. 考试类型优先从顶层目录取
    const examType = parentExamType || '普通高考';
    return { year, examType, region, subject: SUBJECT, stream, note };
}
function sanitizeFileSystemPart(value) {
    return value
        .replace(/[\\/:*?"<>|]/g, '_')
        .replace(/[,()]/g, '_')
        .replace(/\s+/g, '_')
        .replace(/_+/g, '_')
        .replace(/^_+|_+$/g, '');
}
function buildPaperKey(parsed, usedKeys) {
    const baseParts = [parsed.year, parsed.subject, parsed.examType, parsed.region];
    if (parsed.stream)
        baseParts.push(parsed.stream);
    const baseKey = sanitizeFileSystemPart(baseParts.join('_'));
    if (!usedKeys.has(baseKey))
        return baseKey;
    // 基础 key 冲突时，尝试追加备注简称
    if (parsed.note) {
        const noteSlug = sanitizeFileSystemPart(parsed.note).slice(0, 20);
        const withNote = `${baseKey}_${noteSlug}`;
        if (!usedKeys.has(withNote))
            return withNote;
    }
    // 仍冲突则使用自增序号
    let counter = 2;
    while (usedKeys.has(`${baseKey}_${counter}`))
        counter++;
    return `${baseKey}_${counter}`;
}
async function ensureDir(dir) {
    await fs.mkdir(dir, { recursive: true });
}
async function copyFileAtomic(src, dest) {
    await fs.copyFile(src, dest);
}
async function run() {
    console.log(`开始扫描: ${SOURCE_DIR}`);
    console.log(`目标目录: ${env.FILES_DIR}`);
    await ensureDir(env.FILES_DIR);
    const topEntries = await fs.readdir(SOURCE_DIR, { withFileTypes: true });
    const topDirs = topEntries.filter((e) => e.isDirectory());
    let processed = 0;
    let skipped = 0;
    const usedKeys = new Set();
    for (const topDir of topDirs) {
        const examTypeFromFolder = examTypeByFolder[topDir.name];
        if (!examTypeFromFolder) {
            console.log(`跳过未知顶层目录: ${topDir.name}`);
            continue;
        }
        const typeDir = path.join(SOURCE_DIR, topDir.name);
        const files = await collectPdfs(typeDir);
        for (const file of files) {
            const relToType = path.relative(typeDir, file);
            const parentDirParts = path.dirname(relToType).split(path.sep).filter(Boolean);
            const fileName = path.basename(file);
            const parsed = parseFileName(fileName, examTypeFromFolder, parentDirParts);
            const paperKey = buildPaperKey(parsed, usedKeys);
            usedKeys.add(paperKey);
            const title = `${parsed.year}·${parsed.region}·${parsed.subject}`;
            const paperDir = path.join(env.FILES_DIR, paperKey, FILE_TYPE_FOLDER);
            await ensureDir(paperDir);
            const targetFileName = `${paperKey}_${FILE_TYPE_FOLDER}.pdf`;
            const relativeFilePath = path.join(paperKey, FILE_TYPE_FOLDER, targetFileName);
            const targetPath = path.join(env.FILES_DIR, relativeFilePath);
            try {
                await copyFileAtomic(file, targetPath);
                const stat = await fs.stat(targetPath);
                const paperResult = await query(`INSERT INTO papers (year, exam_type, region, subject, stream, note, file_name, title)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
           ON CONFLICT (file_name) DO UPDATE SET
             year = EXCLUDED.year,
             exam_type = EXCLUDED.exam_type,
             region = EXCLUDED.region,
             subject = EXCLUDED.subject,
             stream = EXCLUDED.stream,
             note = EXCLUDED.note,
             title = EXCLUDED.title
           RETURNING id`, [
                    parsed.year,
                    parsed.examType,
                    parsed.region,
                    parsed.subject,
                    parsed.stream ?? null,
                    parsed.note ?? null,
                    paperKey,
                    title,
                ]);
                const paperId = paperResult.rows[0].id;
                await query(`INSERT INTO paper_files (paper_id, file_type, file_path, mime_type, size_bytes)
           VALUES ($1, $2, $3, $4, $5)
           ON CONFLICT (paper_id, file_type) DO UPDATE SET
             file_path = EXCLUDED.file_path,
             mime_type = EXCLUDED.mime_type,
             size_bytes = EXCLUDED.size_bytes`, [paperId, FILE_TYPE, relativeFilePath, 'application/pdf', stat.size]);
                processed++;
                if (processed % 100 === 0) {
                    console.log(`已处理 ${processed} 个文件...`);
                }
            }
            catch (err) {
                console.error(`处理失败: ${file}`, err);
                skipped++;
            }
        }
    }
    console.log(`导入完成。成功: ${processed}, 失败: ${skipped}`);
    await pool.end();
}
async function collectPdfs(dir) {
    const result = [];
    const entries = await fs.readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
        const fullPath = path.join(dir, entry.name);
        if (entry.isDirectory()) {
            const children = await collectPdfs(fullPath);
            result.push(...children);
        }
        else if (entry.isFile() && entry.name.toLowerCase().endsWith('.pdf')) {
            result.push(fullPath);
        }
    }
    return result;
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
