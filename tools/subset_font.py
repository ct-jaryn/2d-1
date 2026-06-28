#!/usr/bin/env python3
"""
根据项目实际使用的中文字符生成子集字体，减小 Web 导出的 .pck 体积。
用法（在项目根目录执行）：
    python tools/subset_font.py
它会读取 assets/fonts/NotoSansCJKsc-Regular.otf，生成子集后覆盖原文件，
并把原文件备份为 *.otf.backup。
"""

import os
import re
import shutil
import sys
from pathlib import Path

from fontTools.subset import Options, Subsetter
from fontTools.ttLib import TTFont

PROJECT_ROOT = Path(__file__).resolve().parent.parent
FONT_PATH = PROJECT_ROOT / "assets" / "fonts" / "NotoSansCJKsc-Regular.otf"
BACKUP_PATH = FONT_PATH.with_suffix(".otf.backup")

# 扫描这些文件中的 CJK 字符
SCAN_EXTENSIONS = {".gd", ".tscn", ".tres", ".json", ".cfg", ".md", ".yml", ".yaml"}

# 额外保留的常见 CJK 标点、空格与换行显示所需字符
EXTRA_CHARS = (
    " \t\n"
    "，。、；：？！\"\"''（）【】《》〈〉「」『』〔〕"
    "—…～·•◆◇○●★☆□■▲▼→←↑↓"
    "①②③④⑤⑥⑦⑧⑨⑩"
    "０１２３４５６７８９"
    "ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ"
    "ａｂｃｄｅｆｇｈｉｊｋｌｍｎｏｐｑｒｓｔｕｖｗｘｙｚ"
)


def collect_cjk_chars(root: Path) -> set[str]:
    chars: set[str] = set()
    for ext in SCAN_EXTENSIONS:
        for path in root.rglob(f"*{ext}"):
            if ".godot" in path.parts or "node_modules" in path.parts:
                continue
            try:
                text = path.read_text(encoding="utf-8", errors="ignore")
            except Exception:
                continue
            # CJK Unified Ideographs + Extension A/B/C/D/E/F
            for ch in text:
                code = ord(ch)
                if (
                    0x4E00 <= code <= 0x9FFF
                    or 0x3400 <= code <= 0x4DBF
                    or 0x20000 <= code <= 0x2A6DF
                    or 0x2A700 <= code <= 0x2B73F
                    or 0x2B740 <= code <= 0x2B81F
                    or 0x2B820 <= code <= 0x2CEAF
                    or 0x2CEB0 <= code <= 0x2EBEF
                    or 0x3000 <= code <= 0x303F  # CJK Symbols and Punctuation
                    or 0xFF00 <= code <= 0xFFEF  # Halfwidth/Fullwidth Forms
                    or 0x3040 <= code <= 0x309F  # Hiragana
                    or 0x30A0 <= code <= 0x30FF  # Katakana
                ):
                    chars.add(ch)
    return chars


def main() -> int:
    if not FONT_PATH.exists():
        print(f"字体文件不存在：{FONT_PATH}", file=sys.stderr)
        return 1

    print("扫描项目文件收集字符...")
    chars = collect_cjk_chars(PROJECT_ROOT)
    chars.update(EXTRA_CHARS)
    text = "".join(sorted(chars))
    print(f"共收集 {len(text)} 个字符")

    if not text:
        print("未找到需要保留的字符，跳过子集化。")
        return 0

    # 备份原字体
    if not BACKUP_PATH.exists():
        shutil.copy2(FONT_PATH, BACKUP_PATH)
        print(f"已备份原字体：{BACKUP_PATH}")

    print("生成子集字体...")
    font = TTFont(str(FONT_PATH))
    options = Options()
    options.notdef_outline = True
    options.recommended_glyphs = True
    options.layout_features = "*"
    options.name_IDs = "*"
    options.name_languages = "*"

    subsetter = Subsetter(options=options)
    subsetter.populate(text=text)
    subsetter.subset(font)

    font.save(str(FONT_PATH))
    print(f"子集化完成：{FONT_PATH}")

    original_size = BACKUP_PATH.stat().st_size
    new_size = FONT_PATH.stat().st_size
    print(f"原大小：{original_size:,} bytes，子集后：{new_size:,} bytes，减小 {original_size - new_size:,} bytes ({(1 - new_size / original_size) * 100:.1f}%)")

    # 提示删除 Godot 字体缓存
    imported = PROJECT_ROOT / ".godot" / "imported"
    if imported.exists():
        for f in imported.glob("NotoSansCJKsc-Regular.otf-*.fontdata"):
            print(f"请手动删除缓存或在 Godot 中重新导入：{f}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
