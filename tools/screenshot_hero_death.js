const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const URL = 'http://localhost:8085/index.html';
const VIEWPORT = { width: 1280, height: 720 };
const OUT_DIR = 'screenshots/hero_anim';

if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });

(async () => {
    const browser = await chromium.launch({ headless: true });
    const context = await browser.newContext({ viewport: VIEWPORT });
    const page = await context.newPage();
    await page.goto(URL);
    await page.waitForTimeout(8000);

    // Start game
    await page.mouse.click(640, 420);
    await page.waitForTimeout(5000);

    // Trigger death animation preview with 't' key
    await page.keyboard.press('t');
    await page.waitForTimeout(1500);
    await page.screenshot({ path: path.join(OUT_DIR, '11_death.png') });
    console.log('Saved death screenshot');

    await browser.close();
})();
