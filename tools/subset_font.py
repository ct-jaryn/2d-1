#!/usr/bin/env python3
"""子集化游戏字体，只保留项目中实际使用的字符，减小 Web 导出体积。"""

import os
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from fontTools.subset import Subsetter, Options
from fontTools.ttLib import TTFont


def collect_used_chars(project_root: Path) -> set:
    chars: set[str] = set()
    # 保留基础 ASCII，避免代码、路径、URL 等意外丢失
    chars.update("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_./:-!%[](){}\n \t")
    # 常见标点
    chars.update("。，、；：？！\"\"''（）【】《》—…·～")

    for ext in (".gd", ".tscn", ".tres", ".cfg", ".md"):
        for p in project_root.rglob(f"*{ext}"):
            if ".godot" in str(p) or ".git" in str(p):
                continue
            try:
                text = p.read_text(encoding="utf-8")
                for ch in text:
                    if ord(ch) > 31:  # 忽略控制字符
                        chars.add(ch)
            except Exception:
                pass
    return chars


def subset_font(input_path: Path, output_path: Path, chars: set[str]) -> None:
    font = TTFont(str(input_path))
    options = Options()
    options.layout_features = ["*"]
    options.name_IDs = ["*"]
    options.notdef_outline = True
    options.recommended_glyphs = True
    options.desubroutinize = True
    options.hinting = False  # 对像素风游戏，关闭 hinting 通常可接受且体积更小

    subsetter = Subsetter(options=options)
    subsetter.populate(text="".join(chars))
    subsetter.subset(font)

    font.save(str(output_path))


def main() -> int:
    project_root = Path(__file__).parent.parent
    font_dir = project_root / "assets" / "fonts"
    input_font = font_dir / "NotoSansCJKsc-Regular.otf"
    output_font = font_dir / "NotoSansCJKsc-Regular-Subset.otf"
    backup_font = font_dir / "NotoSansCJKsc-Regular-Original.otf"

    if not input_font.exists():
        print(f"找不到字体文件: {input_font}")
        return 1

    chars = collect_used_chars(project_root)
    print(f"收集到 {len(chars)} 个唯一字符")

    subset_font(input_font, output_font, chars)

    input_size = input_font.stat().st_size
    output_size = output_font.stat().st_size
    print(f"原始大小: {input_size / 1024 / 1024:.2f} MB")
    print(f"子集化后: {output_size / 1024 / 1024:.2f} MB")
    print(f"体积减少: {(1 - output_size / input_size) * 100:.1f}%")

    # 备份原始字体（仅备份一次）
    if not backup_font.exists():
        input_font.rename(backup_font)
        print(f"已备份原始字体到: {backup_font}")

    # 用子集化字体替换原始字体
    output_font.rename(input_font)
    print(f"已用子集化字体替换: {input_font}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
