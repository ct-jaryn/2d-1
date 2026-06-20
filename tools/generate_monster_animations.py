#!/usr/bin/env python3
"""为 5 种怪物生成 6 帧待机动画精灵图（横向排列）。"""

from __future__ import annotations

import math
import os
from pathlib import Path
from typing import Callable

from PIL import Image, ImageFilter

BASE_DIR = Path(__file__).resolve().parent.parent
SRC_DIR = BASE_DIR / "assets" / "images"
OUT_DIR = BASE_DIR / "assets" / "images" / "animations" / "monsters"
OUT_DIR.mkdir(parents=True, exist_ok=True)

FRAME_COUNT = 6


def save_sheet(frames: list[Image.Image], out_path: Path) -> None:
    width = sum(f.width for f in frames)
    height = max(f.height for f in frames)
    sheet = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    x = 0
    for f in frames:
        sheet.paste(f, (x, 0), f)
        x += f.width
    sheet.save(out_path)
    print(f"saved {out_path}")


def make_slime_idle(src: Image.Image) -> list[Image.Image]:
    """史莱姆：果冻式上下弹跳 + 左右挤压。"""
    frames: list[Image.Image] = []
    for i in range(FRAME_COUNT):
        t = i / FRAME_COUNT
        # 0->1->0 的弹跳曲线
        bounce = math.sin(t * math.pi * 2)
        scale_y = 1.0 + bounce * 0.08
        scale_x = 1.0 - bounce * 0.05
        offset_y = int(-bounce * 6)
        w = int(src.width * scale_x)
        h = int(src.height * scale_y)
        frame = src.resize((w, h), Image.Resampling.LANCZOS)
        # 居中放置到底部
        canvas = Image.new("RGBA", src.size, (0, 0, 0, 0))
        x = (canvas.width - frame.width) // 2
        y = canvas.height - frame.height + offset_y
        canvas.paste(frame, (x, y), frame)
        frames.append(canvas)
    return frames


def make_goblin_idle(src: Image.Image) -> list[Image.Image]:
    """哥布林：呼吸式轻微缩放 + 武器上下摆动。"""
    frames: list[Image.Image] = []
    for i in range(FRAME_COUNT):
        t = i / FRAME_COUNT
        breath = math.sin(t * math.pi * 2)
        scale_y = 1.0 + breath * 0.025
        scale_x = 1.0 + breath * 0.015
        offset_y = int(-breath * 3)
        w = int(src.width * scale_x)
        h = int(src.height * scale_y)
        frame = src.resize((w, h), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", src.size, (0, 0, 0, 0))
        x = (canvas.width - frame.width) // 2
        y = canvas.height - frame.height + offset_y
        canvas.paste(frame, (x, y), frame)
        frames.append(canvas)
    return frames


def make_bat_idle(src: Image.Image) -> list[Image.Image]:
    """蝙蝠：上下悬浮 + 轻微水平倾斜。"""
    frames: list[Image.Image] = []
    for i in range(FRAME_COUNT):
        t = i / FRAME_COUNT
        hover = math.sin(t * math.pi * 2)
        offset_y = int(-hover * 8)
        # 轻微水平错切模拟翅膀扇动后的悬浮
        skew = math.sin(t * math.pi * 2 + math.pi / 4) * 2
        frame = src.transform(
            src.size,
            Image.Transform.AFFINE,
            (1, 0.05 * skew, 0, 0, 1, 0),
            resample=Image.Resampling.BILINEAR,
        )
        canvas = Image.new("RGBA", src.size, (0, 0, 0, 0))
        x = (canvas.width - frame.width) // 2
        y = (canvas.height - frame.height) // 2 + offset_y
        canvas.paste(frame, (x, y), frame)
        frames.append(canvas)
    return frames


def make_skeleton_idle(src: Image.Image) -> list[Image.Image]:
    """骷髅兵：骨骼轻微摇晃 + 呼吸。"""
    frames: list[Image.Image] = []
    for i in range(FRAME_COUNT):
        t = i / FRAME_COUNT
        sway = math.sin(t * math.pi * 2)
        scale_y = 1.0 + sway * 0.02
        offset_y = int(-abs(sway) * 2)
        frame = src.resize(
            (int(src.width * 1.0), int(src.height * scale_y)),
            Image.Resampling.LANCZOS,
        )
        canvas = Image.new("RGBA", src.size, (0, 0, 0, 0))
        x = (canvas.width - frame.width) // 2
        y = canvas.height - frame.height + offset_y
        canvas.paste(frame, (x, y), frame)
        frames.append(canvas)
    return frames


def make_dragon_idle(src: Image.Image) -> list[Image.Image]:
    """恶龙：沉重呼吸 + 轻微上下。"""
    frames: list[Image.Image] = []
    for i in range(FRAME_COUNT):
        t = i / FRAME_COUNT
        breath = math.sin(t * math.pi * 2)
        scale_x = 1.0 + breath * 0.02
        scale_y = 1.0 + breath * 0.03
        offset_y = int(-breath * 4)
        w = int(src.width * scale_x)
        h = int(src.height * scale_y)
        frame = src.resize((w, h), Image.Resampling.LANCZOS)
        canvas = Image.new("RGBA", src.size, (0, 0, 0, 0))
        x = (canvas.width - frame.width) // 2
        y = canvas.height - frame.height + offset_y
        canvas.paste(frame, (x, y), frame)
        frames.append(canvas)
    return frames


MONSTERS: dict[str, Callable[[Image.Image], list[Image.Image]]] = {
    "slime": make_slime_idle,
    "goblin": make_goblin_idle,
    "bat": make_bat_idle,
    "skeleton": make_skeleton_idle,
    "dragon_boss": make_dragon_idle,
}


def main() -> None:
    for name, builder in MONSTERS.items():
        src_path = SRC_DIR / f"{name}.png"
        if not src_path.exists():
            print(f"skip missing {src_path}")
            continue
        src = Image.open(src_path).convert("RGBA")
        frames = builder(src)
        out_path = OUT_DIR / f"{name}_idle.png"
        save_sheet(frames, out_path)


if __name__ == "__main__":
    main()
