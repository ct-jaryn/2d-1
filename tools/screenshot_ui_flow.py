import sys
import os
from playwright.sync_api import sync_playwright

URL = "http://localhost:8085/index.html"
VIEWPORT = {"width": 1280, "height": 720}
OUT_DIR = "screenshots"

os.makedirs(OUT_DIR, exist_ok=True)


def click_and_shot(page, x, y, name, wait=3000):
    page.mouse.click(x, y)
    page.wait_for_timeout(wait)
    path = os.path.join(OUT_DIR, f"{name}.png")
    page.screenshot(path=path)
    print(f"Saved {path}")


def main():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(viewport=VIEWPORT)
        page = context.new_page()
        page.goto(URL)
        page.wait_for_timeout(8000)
        page.screenshot(path=os.path.join(OUT_DIR, "01_title.png"))

        # Click "开始新游戏" button in center
        click_and_shot(page, 640, 420, "02_after_start", wait=5000)

        # Bottom navigation buttons approximate positions for 1280x720
        # They are in a HFlowContainer at bottom center, around y=640-680
        buttons = [
            ("battle_boss", 430, 660),
            ("equipment", 540, 660),
            ("shop", 640, 660),
            ("stats", 740, 660),
            ("achievements", 840, 660),
            ("quests", 940, 660),
        ]

        for name, x, y in buttons:
            click_and_shot(page, x, y, f"03_{name}", wait=3000)
            # close any opened sub-UI by clicking a close/return area if needed
            # For now, assume buttons toggle; click same to close if stays open

        browser.close()


if __name__ == "__main__":
    main()
