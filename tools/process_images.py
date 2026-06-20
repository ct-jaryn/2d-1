from PIL import Image
import os
from pathlib import Path

INPUT_DIR = Path("assets/images")
OUTPUT_DIR = Path("assets/images_processed")
OUTPUT_DIR.mkdir(exist_ok=True)

# 目标尺寸
TARGETS = {
    "hero": (160, 160),
    "slime": (120, 120),
    "goblin": (140, 140),
    "bat": (120, 120),
    "skeleton": (140, 140),
    "dragon_boss": (240, 240),
    "title_bg": (1280, 720),
    "equipment_weapon": (64, 64),
    "equipment_helmet": (64, 64),
    "equipment_armor": (64, 64),
    "equipment_boots": (64, 64),
    "equipment_ring": (64, 64),
}


def remove_background(img: Image.Image, threshold: int = 245) -> Image.Image:
    """从四个角 flood fill 去除连通的白色背景"""
    img = img.convert("RGBA")
    width, height = img.size

    # 创建透明图层
    result = Image.new("RGBA", img.size, (0, 0, 0, 0))
    result.paste(img, (0, 0), img)

    # 创建 mask：背景像素为 0，前景为 255
    # 先转换为灰度，接近白色的为背景
    gray = img.convert("L")
    mask = Image.new("L", img.size, 0)
    pixels = mask.load()
    for y in range(height):
        for x in range(width):
            if gray.getpixel((x, y)) >= threshold:
                pixels[x, y] = 0
            else:
                pixels[x, y] = 255

    # 从四个角 flood fill 背景区域，标记为透明
    # 使用临时图像来跟踪已访问像素
    visited = Image.new("L", img.size, 0)
    stack = [(0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1)]
    visited_pixels = visited.load()
    mask_pixels = mask.load()

    while stack:
        x, y = stack.pop()
        if x < 0 or x >= width or y < 0 or y >= height:
            continue
        if visited_pixels[x, y] or mask_pixels[x, y] != 0:
            continue
        visited_pixels[x, y] = 255
        stack.extend([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)])

    # 合并 mask：visited（背景）为 0，其他 mask 保持
    final_mask = Image.new("L", img.size, 0)
    final_pixels = final_mask.load()
    for y in range(height):
        for x in range(width):
            if visited_pixels[x, y] == 0 and mask_pixels[x, y] == 255:
                final_pixels[x, y] = 255

    result.putalpha(final_mask)
    return result


def crop_to_content(img: Image.Image) -> Image.Image:
    """裁剪到非透明内容"""
    bbox = img.getbbox()
    if bbox:
        return img.crop(bbox)
    return img


def resize_keep_aspect(img: Image.Image, target_size: tuple) -> Image.Image:
    """按比例缩放，目标尺寸为最大宽高"""
    img.thumbnail(target_size, Image.Resampling.LANCZOS)
    # 创建目标尺寸画布居中放置
    canvas = Image.new("RGBA", target_size, (0, 0, 0, 0))
    x = (target_size[0] - img.width) // 2
    y = (target_size[1] - img.height) // 2
    canvas.paste(img, (x, y), img)
    return canvas


def process_image(name: str, target_size: tuple):
    input_path = INPUT_DIR / f"{name}.png"
    if not input_path.exists():
        print(f"Skip {name}: file not found")
        return

    print(f"Processing {name}...")
    img = Image.open(input_path)

    if name == "title_bg":
        # 标题背景不需要去背，直接缩放
        img = img.convert("RGBA")
        img = img.resize(target_size, Image.Resampling.LANCZOS)
        img.save(OUTPUT_DIR / f"{name}.png")
    else:
        img = remove_background(img)
        img = crop_to_content(img)
        img = resize_keep_aspect(img, target_size)
        img.save(OUTPUT_DIR / f"{name}.png")

    print(f"  Saved to {OUTPUT_DIR / f'{name}.png'}")


def main():
    for name, target_size in TARGETS.items():
        process_image(name, target_size)
    print("Done")


if __name__ == "__main__":
    main()
