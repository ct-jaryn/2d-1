#!/usr/bin/env python3
"""
Godot UI 点击测试脚本。

用法示例：
    python tools/click_test.py \
        --exe "Godot_v4.3-stable_win64_console.exe" \
        --project . \
        --click-x 323 --click-y 690 \
        --output "C:/Temp/click_test_after.png"

默认点击「装备」按钮位置（1280x720 窗口客户区坐标）。
"""

import argparse
import os
import subprocess
import sys
import time
from pathlib import Path

import win32api
import win32con
import win32gui


DEFAULT_GODOT_EXE = "Godot_v4.3-stable_win64_console.exe"
DEFAULT_RESOLUTION = "1280x720"
DEFAULT_CLICK_X = 323
DEFAULT_CLICK_Y = 690
DEFAULT_TITLE_BAR_HEIGHT = 30
DEFAULT_WAIT_AFTER_START = 6.0
DEFAULT_WAIT_AFTER_CLICK = 1.5


def find_godot_window(title_keywords: list[str], timeout: float = 10.0) -> int | None:
    """查找可见的 Godot 游戏窗口句柄。"""
    hwnd = None
    deadline = time.time() + timeout
    while time.time() < deadline:
        def enum_callback(h: int, _extra: object) -> None:
            nonlocal hwnd
            if hwnd is not None:
                return
            if win32gui.IsWindowVisible(h):
                title = win32gui.GetWindowText(h)
                if any(kw in title for kw in title_keywords):
                    hwnd = h

        win32gui.EnumWindows(enum_callback, None)
        if hwnd:
            return hwnd
        time.sleep(0.5)
    return None


def parse_resolution(resolution: str) -> tuple[int, int]:
    parts = resolution.lower().split("x")
    if len(parts) != 2:
        raise ValueError(f"无效分辨率格式：{resolution}，应为 WIDTHxHEIGHT")
    return int(parts[0]), int(parts[1])


def main() -> int:
    parser = argparse.ArgumentParser(description="Godot UI 点击测试工具")
    parser.add_argument("--exe", default=DEFAULT_GODOT_EXE, help="Godot 可执行文件路径或名称")
    parser.add_argument("--project", default=".", help="项目目录路径")
    parser.add_argument("--resolution", default=DEFAULT_RESOLUTION, help="窗口分辨率，如 1280x720")
    parser.add_argument("--click-x", type=int, default=DEFAULT_CLICK_X, help="客户区点击 X 坐标")
    parser.add_argument("--click-y", type=int, default=DEFAULT_CLICK_Y, help="客户区点击 Y 坐标")
    parser.add_argument("--title-bar-height", type=int, default=DEFAULT_TITLE_BAR_HEIGHT, help="标题栏高度估算值")
    parser.add_argument("--output", default=None, help="截图保存路径")
    parser.add_argument("--no-screenshot", action="store_true", help="不截取屏幕")
    args = parser.parse_args()

    project_path = Path(args.project).resolve()
    exe_path = Path(args.exe)
    if not exe_path.is_absolute():
        # 优先在项目目录查找，再在 PATH 中查找
        candidate = project_path / args.exe
        if candidate.exists():
            exe_path = candidate
        else:
            exe_path = exe_path.resolve()

    if not exe_path.exists():
        print(f"找不到 Godot 可执行文件：{exe_path}", file=sys.stderr)
        return 1

    width, height = parse_resolution(args.resolution)

    print(f"启动 {exe_path}，项目 {project_path}")
    proc = subprocess.Popen(
        [str(exe_path), "--path", str(project_path), "--resolution", f"{width}x{height}"],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    time.sleep(DEFAULT_WAIT_AFTER_START)

    hwnd = find_godot_window(["Pixel Idle Hero", "Godot Engine"])
    if hwnd is None:
        print("未找到 Godot 窗口", file=sys.stderr)
        proc.terminate()
        return 1

    print(f"找到窗口 HWND: {hwnd}")
    rect = win32gui.GetWindowRect(hwnd)
    print(f"窗口区域：{rect}")
    wx, wy = rect[0], rect[1]

    screen_x = wx + args.click_x
    screen_y = wy + args.title_bar_height + args.click_y
    print(f"点击屏幕坐标 ({screen_x}, {screen_y})")

    win32api.SetCursorPos((screen_x, screen_y))
    time.sleep(0.2)
    win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
    time.sleep(0.1)
    win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
    time.sleep(DEFAULT_WAIT_AFTER_CLICK)

    if not args.no_screenshot:
        output_path = args.output
        if output_path is None:
            output_path = os.path.join(os.environ.get("TEMP", "/tmp"), "click_test_after.png")
        # 这里默认使用 Kimi screenshot skill 的 PowerShell 脚本；可替换为任意截图工具
        ps_script = "E:/C_Moved/IDE/.kimi-code/skills/screenshot/scripts/take_screenshot.ps1"
        region = f"{wx},{wy + args.title_bar_height},{rect[2] - wx},{rect[3] - wy - args.title_bar_height}"
        ps_cmd = (
            f'powershell -ExecutionPolicy Bypass -File "{ps_script}" '
            f'-Path "{output_path}" -Region {region}'
        )
        os.system(ps_cmd)
        print(f"截图保存至：{output_path}")

    proc.terminate()
    print("完成")
    return 0


if __name__ == "__main__":
    sys.exit(main())
