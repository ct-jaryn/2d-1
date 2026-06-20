import os
import json
import time
import urllib.request
import urllib.error
from pathlib import Path

MCP_URL = "https://image-generate.app.baizhi.cloud/mcp"
TOKEN = os.environ.get("BAIZHI_IMAGE_GENERATE_MCP_TOKEN", "")
TASKS_DIR = Path("tasks")
OUTPUT_DIR = Path("assets/images")

TASKS_DIR.mkdir(exist_ok=True)
OUTPUT_DIR.mkdir(exist_ok=True)

ASSETS = [
    ("battle_bg", "A seamless 2.5D pixel art grassland battle background, rolling green hills, distant mountains, blue sky with white clouds, retro JRPG style, warm afternoon light, no characters, wide horizontal composition", "16:9"),
    ("panel_bg", "A pixel art UI panel texture, dark blue stone with golden border, decorative corners, retro JRPG menu background, 1:1 square tileable pattern", "1:1"),
    ("button_normal", "A pixel art UI button texture, brown wooden with golden border, beveled, retro JRPG style, 1:1 square", "1:1"),
    ("button_hover", "A pixel art UI button texture, light brown wooden with bright golden border, glowing edges, retro JRPG style, 1:1 square", "1:1"),
    ("boss_arena", "A dark 2.5D pixel art boss arena background, volcanic landscape with lava cracks, ominous red sky, castle ruins, retro JRPG style, wide horizontal composition", "16:9"),
    ("shop_bg", "A cozy pixel art shop interior background, wooden shelves with potions and weapons, warm lantern light, retro JRPG style, wide horizontal composition", "16:9"),
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
        print(f"Failed to extract task_id: {e}")
        return ""


def create_task(name: str, prompt: str, ratio: str) -> str:
    response = mcp_call("image_generate_text_to_image", {"prompt": prompt, "ratio": ratio})
    task_id = extract_task_id(response)
    if task_id:
        meta_path = TASKS_DIR / f"{name}.json"
        meta_path.write_text(json.dumps({"name": name, "task_id": task_id, "status": "processing"}, indent=2))
        print(f"Created {name} -> {task_id}")
    return task_id


def query_task(task_id: str) -> dict:
    response = mcp_call("image_generate_query_task", {"task_id": task_id})
    try:
        content = response["result"]["content"][0]["text"]
        return json.loads(content)
    except (KeyError, IndexError, json.JSONDecodeError) as e:
        return {"status": "failed"}


def download_image(url: str, path: Path):
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {TOKEN}"})
    with urllib.request.urlopen(req, timeout=120) as resp:
        path.write_bytes(resp.read())
    print(f"Downloaded {path}")


def main():
    if not TOKEN:
        print("Token not set")
        return

    for name, prompt, ratio in ASSETS:
        create_task(name, prompt, ratio)
        time.sleep(1)

    pending = {meta.stem: json.loads(meta.read_text()) for meta in TASKS_DIR.glob("*.json")}
    while pending:
        for name, meta in list(pending.items()):
            result = query_task(meta["task_id"])
            status = result.get("status", "failed")
            if status == "completed":
                urls = result.get("image_urls", [])
                if urls:
                    ext = ".jpg" if urls[0].lower().endswith((".jpg", ".jpeg")) else ".png"
                    download_image(urls[0], OUTPUT_DIR / f"{name}{ext}")
                pending.pop(name)
            elif status == "failed":
                pending.pop(name)
        if pending:
            print(f"Waiting for {len(pending)} tasks...")
            time.sleep(15)
    print("Done")


if __name__ == "__main__":
    main()
