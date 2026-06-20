const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const URL = 'http://localhost:8085/index.html';
const VIEWPORT = { width: 1280, height: 720 };
const OUT_DIR = 'screenshots';

if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

async function clickAndShot(page, x, y, name, wait = 3000) {
    await page.mouse.click(x, y);
    await page.waitForTimeout(wait);
    const file = path.join(OUT_DIR, `${name}.png`);
    await page.screenshot({ path: file });
    console.log(`Saved ${file}`);
}

(async () => {
    const browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({ viewport: VIEWPORT });
    const page = await context.newPage();
    await page.goto(URL);
    await page.waitForTimeout(8000);
    await page.screenshot({ path: path.join(OUT_DIR, '01_title.png') });

    await clickAndShot(page, 640, 420, '02_after_start', 5000);

    const buttons = [
        ['battle_boss', 110, 690],
        ['equipment', 320, 690],
        ['shop', 535, 690],
        ['stats', 750, 690],
        ['achievements', 960, 690],
        ['quests', 1175, 690],
    ];

    for (const [name, x, y] of buttons) {
        await clickAndShot(page, x, y, `03_${name}`, 3000);
        // 点击左上角返回按钮回到战斗主界面
        await page.mouse.click(45, 45);
        await page.waitForTimeout(1500);
    }

    await browser.close();
})();
