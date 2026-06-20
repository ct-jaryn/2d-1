const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const URL = 'http://localhost:8085/index.html';
const VIEWPORT = { width: 1280, height: 720 };
const OUT_DIR = 'screenshots/hero_anim';

if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

async function saveShot(page, name) {
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
    await saveShot(page, '01_title');

    // Start game
    await page.mouse.click(640, 420);
    await page.waitForTimeout(5000);

    // Capture several frames over time to show idle/attack/hit animations
    const captures = [
        ['02_battle_0s', 0],
        ['03_battle_0p5s', 500],
        ['04_battle_1s', 500],
        ['05_battle_1p5s', 500],
        ['06_battle_2s', 500],
        ['07_battle_2p5s', 500],
        ['08_battle_3s', 500],
        ['09_battle_3p5s', 500],
        ['10_battle_4s', 500],
    ];

    for (const [name, delay] of captures) {
        await page.waitForTimeout(delay);
        await saveShot(page, name);
    }

    await browser.close();
})();
