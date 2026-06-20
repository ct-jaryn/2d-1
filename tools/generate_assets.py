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
    ("hero", "A cute pixel art hero warrior in 2.5D style, facing right, small chibi proportion, wearing blue armor and red cape, holding a silver sword and shield, clean white background, retro JRPG sprite, highly detailed pixel art, soft shadow", "1:1"),
    ("slime", "A cute pixel art green slime in 2.5D style, chibi proportion, round jelly body, big eyes, clean white background, retro JRPG enemy sprite, soft shadow", "1:1"),
    ("goblin", "A pixel art green goblin in 2.5D style, chibi proportion, holding a dagger, mischievous expression, clean white background, retro JRPG enemy sprite, soft shadow", "1:1"),
    ("bat", "A pixel art purple bat in 2.5D style, chibi proportion, wings spread, fangs, clean white background, retro JRPG enemy sprite, soft shadow", "1:1"),
    ("skeleton", "A pixel art skeleton warrior in 2.5D style, chibi proportion, holding a bone sword, clean white background, retro JRPG enemy sprite, soft shadow", "1:1"),
    ("dragon_boss", "A pixel art red dragon boss in 2.5D style, large chibi proportion, wings, horns, fierce but cute, clean white background, retro JRPG boss sprite, soft shadow", "1:1"),
    ("title_bg", "A 2.5D pixel art fantasy RPG title screen background, a cute chibi hero standing on a hill looking at a distant castle and a flying dragon, sunset sky with warm orange and purple clouds, grassland, atmospheric perspective, retro JRPG style, wide cinematic shot", "16:9"),
    ("equipment_weapon", "A pixel art silver sword equipment icon, 64x64 style, clean white background, retro JRPG item icon, centered, soft shadow", "1:1"),
    ("equipment_helmet", "A pixel art knight helmet equipment icon, 64x64 style, clean white background, retro JRPG item icon, centered, soft shadow", "1:1"),
    ("equipment_armor", "A pixel art steel chestplate armor equipment icon, 64x64 style, clean white background, retro JRPG item icon, centered, soft shadow", "1:1"),
    ("equipment_boots", "A pixel art leather boots equipment icon, 64x64 style, clean white background, retro JRPG item icon, centered, soft shadow", "1:1"),
    ("equipment_ring", "A pixel art golden ring with gem equipment icon, 64x64 style, clean white background, retro JRPG item icon, centered, soft shadow", "1:1"),
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


def main():
    if not TOKEN:
        print("BAIZHI_IMAGE_GENERATE_MCP_TOKEN not set")
        return

    # Create tasks
    for name, prompt, ratio in ASSETS:
        create_task(name, prompt, ratio)
        time.sleep(1)

    # Poll until all completed
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
                    ext = ".png"
                    if urls[0].lower().endswith(".jpg") or urls[0].lower().endswith(".jpeg"):
                        ext = ".jpg"
                    download_image(urls[0], OUTPUT_DIR / f"{name}{ext}")
                pending.pop(name)
            elif status == "failed":
                print(f"Task {name} failed")
                pending.pop(name)

        if pending:
            print(f"Waiting for {len(pending)} tasks...")
            time.sleep(15)

    print("Done")


if __name__ == "__main__":
    main()
