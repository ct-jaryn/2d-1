from pathlib import Path
from PIL import Image

OUTPUT_DIR = Path("assets/images/animations/hero")
FRAME_SIZE = 256

ASSETS = [
    ("hero_idle", 4),
    ("hero_attack", 4),
    ("hero_hit", 2),
    ("hero_death", 4),
]


def remove_background(img: Image.Image, threshold: int = 235) -> Image.Image:
    """结合亮度与饱和度，从四个角 flood fill 去除连通的浅色背景。"""
    img = img.convert("RGBA")
    width, height = img.size

    hsv = img.convert("HSV")
    gray = img.convert("L")
    mask = Image.new("L", img.size, 0)
    mask_pixels = mask.load()
    for y in range(height):
        for x in range(width):
            h, s, v = hsv.getpixel((x, y))
            lightness = gray.getpixel((x, y))
            # 背景：亮度高且饱和度低（灰/白）
            is_bg = lightness >= threshold or (v >= 230 and s <= 25)
            mask_pixels[x, y] = 0 if is_bg else 255

    # 从四个角 flood fill 背景区域
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

    # 最终 alpha：visited（背景）为 0，mask 中前景保持 255
    alpha = Image.new("L", img.size, 0)
    alpha_pixels = alpha.load()
    for y in range(height):
        for x in range(width):
            if visited_pixels[x, y] == 0 and mask_pixels[x, y] == 255:
                alpha_pixels[x, y] = 255

    img.putalpha(alpha)
    return img


def split_frames(img: Image.Image, frame_count: int) -> list[Image.Image]:
    """将横向条带等分为 frame_count 帧。"""
    width, height = img.size
    frame_width = width // frame_count
    frames = []
    for i in range(frame_count):
        left = i * frame_width
        right = left + frame_width
        frames.append(img.crop((left, 0, right, height)))
    return frames


def crop_to_content(img: Image.Image) -> Image.Image:
    """裁剪到非透明内容的 bounding box。"""
    bbox = img.getbbox()
    if bbox:
        return img.crop(bbox)
    return img


def fit_to_square(img: Image.Image, size: int) -> Image.Image:
    """保持宽高比将内容缩放至 size x size 的透明画布中居中。"""
    img.thumbnail((size, size), Image.Resampling.NEAREST)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    x = (size - img.width) // 2
    y = (size - img.height) // 2
    canvas.paste(img, (x, y), img)
    return canvas


def process_animation(name: str, frame_count: int) -> None:
    raw_path = OUTPUT_DIR / f"{name}_raw.png"
    dst_path = OUTPUT_DIR / f"{name}.png"
    if not raw_path.exists():
        print(f"Skip {name}: raw file not found")
        return

    img = Image.open(raw_path).convert("RGBA")
    img = remove_background(img)

    # 先整体裁剪去除空白边距，再均分帧
    img = crop_to_content(img)
    frames = split_frames(img, frame_count)

    # 每帧裁剪到内容后等比缩放到目标方块
    processed = []
    for frame in frames:
        frame = crop_to_content(frame)
        frame = fit_to_square(frame, FRAME_SIZE)
        processed.append(frame)

    # 拼接成横向条带
    sheet = Image.new("RGBA", (FRAME_SIZE * frame_count, FRAME_SIZE), (0, 0, 0, 0))
    for i, frame in enumerate(processed):
        sheet.paste(frame, (i * FRAME_SIZE, 0), frame)

    sheet.save(dst_path)
    print(f"Saved {dst_path} ({frame_count} frames @ {FRAME_SIZE}x{FRAME_SIZE})")


def main() -> None:
    for name, frames in ASSETS:
        process_animation(name, frames)
    print("Done")


if __name__ == "__main__":
    main()
