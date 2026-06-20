import os
import json
import time
import urllib.request
import urllib.error
from pathlib import Path
from PIL import Image

MCP_URL = "https://image-generate.app.baizhi.cloud/mcp"
TOKEN = os.environ.get("BAIZHI_IMAGE_GENERATE_MCP_TOKEN", "")
TASKS_DIR = Path("tasks/hero_anims_6frame")
OUTPUT_DIR = Path("assets/images/animations/hero")

TASKS_DIR.mkdir(parents=True, exist_ok=True)
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

BASE_DESC = (
    "A pixel art sprite sheet of a cute chibi hero warrior for a retro JRPG, "
    "brown short hair, blue armor with silver accents, red cape, holding a silver sword, "
    "facing right, transparent background, clean crisp pixel art, no shadow, "
    "consistent character design across all frames, "
)

FRAME_SIZE = 256

ASSETS = [
    (
        "hero_idle",
        BASE_DESC
        + "horizontal strip of 6 equal frames for a smooth looping idle animation: "
        "frame1 standing stance, frame2 slight inhale, frame3 highest chest, "
        "frame4 slight exhale, frame5 lowest chest, frame6 returning to stance, "
        "subtle breathing and cape flutter, feet planted",
        "6:1",
        6,
    ),
    (
        "hero_attack",
        BASE_DESC
        + "horizontal strip of 6 equal frames for a smooth attack animation: "
        "frame1 ready stance, frame2 windup raising sword, frame3 leaning back, "
        "frame4 sword slash forward, frame5 slash follow-through, frame6 recovering to stance, "
        "dynamic motion with blue slash effect",
        "6:1",
        6,
    ),
    (
        "hero_hit",
        BASE_DESC
        + "horizontal strip of 6 equal frames for a smooth hurt reaction: "
        "frame1 normal stance, frame2 flinching, frame3 recoiling backward, "
        "frame4 pained expression, frame5 staggering, frame6 recovering to stance",
        "6:1",
        6,
    ),
    (
        "hero_death",
        BASE_DESC
        + "horizontal strip of 6 equal frames for a smooth death animation: "
        "frame1 standing, frame2 staggering, frame3 falling to knees, "
        "frame4 collapsing forward, frame5 lying on ground, frame6 fully collapsed",
        "6:1",
        6,
    ),
]


def mcp_call(tool_name: str, arguments: dict) -> dict:
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {"name": tool_name, "arguments": arguments},
    }
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        MCP_URL,
        data=data,
        headers={
            "Authorization": f"Bearer {TOKEN}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.URLError as e:
        print(f"MCP call failed: {e}")
        return {}


def extract_task_id(response: dict) -> str:
    try:
        content = response["result"]["content"][0]["text"]
        data = json.loads(content)
        return data.get("task_id", "")
    except (KeyError, IndexError, json.JSONDecodeError) as e:
        print(f"Failed to extract task_id: {e}, response: {response}")
        return ""


def create_task(name: str, prompt: str, ratio: str) -> str:
    response = mcp_call("image_generate_text_to_image", {"prompt": prompt, "ratio": ratio})
    task_id = extract_task_id(response)
    if task_id:
        meta_path = TASKS_DIR / f"{name}.json"
        meta_path.write_text(json.dumps({"name": name, "task_id": task_id, "status": "processing"}, indent=2))
        print(f"Created {name} -> {task_id}")
    else:
        print(f"Failed to create task for {name}")
    return task_id


def query_task(task_id: str) -> dict:
    response = mcp_call("image_generate_query_task", {"task_id": task_id})
    try:
        content = response["result"]["content"][0]["text"]
        return json.loads(content)
    except (KeyError, IndexError, json.JSONDecodeError) as e:
        print(f"Failed to query task {task_id}: {e}")
        return {"status": "failed"}


def download_image(url: str, path: Path):
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {TOKEN}"})
    with urllib.request.urlopen(req, timeout=120) as resp:
        path.write_bytes(resp.read())
    print(f"Downloaded {path}")


def remove_background(img: Image.Image, threshold: int = 235) -> Image.Image:
    """结合亮度与饱和度，从四个角 flood fill 去除连通的浅色背景。"""
    width, height = img.size
    hsv = img.convert("HSV")
    gray = img.convert("L")
    mask = Image.new("L", img.size, 0)
    mask_pixels = mask.load()
    for y in range(height):
        for x in range(width):
            h, s, v = hsv.getpixel((x, y))
            lightness = gray.getpixel((x, y))
            is_bg = lightness >= threshold or (v >= 230 and s <= 25)
            mask_pixels[x, y] = 0 if is_bg else 255

    visited = Image.new("L", img.size, 0)
    visited_pixels = visited.load()
    stack = [(0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1)]
    while stack:
        x, y = stack.pop()
        if x < 0 or x >= width or y < 0 or y >= height:
            continue
        if visited_pixels[x, y] or mask_pixels[x, y] != 0:
            continue
        visited_pixels[x, y] = 255
        stack.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])

    alpha = Image.new("L", img.size, 0)
    alpha_pixels = alpha.load()
    for y in range(height):
        for x in range(width):
            if visited_pixels[x, y] == 0 and mask_pixels[x, y] == 255:
                alpha_pixels[x, y] = 255

    img.putalpha(alpha)
    return img


def crop_to_content(img: Image.Image) -> Image.Image:
    bbox = img.getbbox()
    return img.crop(bbox) if bbox else img


def fit_to_square(img: Image.Image, size: int) -> Image.Image:
    """保持宽高比将内容缩放至 size x size 的透明画布中居中。"""
    img.thumbnail((size, size), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    x = (size - img.width) // 2
    y = (size - img.height) // 2
    canvas.paste(img, (x, y), img)
    return canvas


def process_spritesheet(src: Path, dst: Path, frame_count: int) -> None:
    img = Image.open(src).convert("RGBA")
    img = remove_background(img)
    img = crop_to_content(img)

    raw_width, raw_height = img.size
    frame_width = raw_width // frame_count
    frames = []
    for i in range(frame_count):
        frame = img.crop((i * frame_width, 0, (i + 1) * frame_width, raw_height))
        frame = crop_to_content(frame)
        frame = fit_to_square(frame, FRAME_SIZE)
        frames.append(frame)

    sheet = Image.new("RGBA", (FRAME_SIZE * frame_count, FRAME_SIZE), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * FRAME_SIZE, 0), frame)
    sheet.save(dst)
    print(f"Processed {dst} ({frame_count} frames @ {FRAME_SIZE}x{FRAME_SIZE})")


def main():
    if not TOKEN:
        print("BAIZHI_IMAGE_GENERATE_MCP_TOKEN not set")
        return

    for name, prompt, ratio, frames in ASSETS:
        create_task(name, prompt, ratio)
        time.sleep(1)

    pending = {meta.stem: json.loads(meta.read_text()) for meta in TASKS_DIR.glob("*.json")}
    while pending:
        for name, meta in list(pending.items()):
            result = query_task(meta["task_id"])
            status = result.get("status", "failed")
            meta["status"] = status
            meta["result"] = result
            (TASKS_DIR / f"{name}.json").write_text(json.dumps(meta, indent=2))

            if status == "completed":
                urls = result.get("image_urls", [])
                if urls:
                    raw_path = OUTPUT_DIR / f"{name}_raw.png"
                    download_image(urls[0], raw_path)
                    frames_count = next(f for n, _, _, f in ASSETS if n == name)
                    process_spritesheet(raw_path, OUTPUT_DIR / f"{name}.png", frames_count)
                pending.pop(name)
            elif status == "failed":
                print(f"Task {name} failed")
                pending.pop(name)

        if pending:
            print(f"Waiting for {len(pending)} tasks...")
            time.sleep(20)

    print("Done")


if __name__ == "__main__":
    main()
