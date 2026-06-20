import subprocess
import time
import win32gui
import win32api
import win32con
import os

godot_exe = r"D:\kimi_PRO\123456\pixel-idle-hero\Godot_v4.3-stable_win64_console.exe"
project_path = r"D:\kimi_PRO\123456\pixel-idle-hero"

# Start Godot
proc = subprocess.Popen([godot_exe, "--path", project_path, "--resolution", "1280x720"],
                        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
time.sleep(6)

# Find Godot window
hwnd = None
for _ in range(20):
    def callback(h, extra):
        global hwnd
        if win32gui.IsWindowVisible(h):
            title = win32gui.GetWindowText(h)
            if "Pixel Idle Hero" in title or "Godot Engine" in title:
                hwnd = h
    win32gui.EnumWindows(callback, None)
    if hwnd:
        break
    time.sleep(0.5)

if not hwnd:
    print("Window not found")
    proc.terminate()
    exit(1)

print(f"Found HWND: {hwnd}")
rect = win32gui.GetWindowRect(hwnd)
print(f"Window rect: {rect}")
wx, wy = rect[0], rect[1]

# Click "Equipment" button (approx client position)
client_x = 323
client_y = 690
# Approx title bar height 30
screen_x = wx + client_x
screen_y = wy + 30 + client_y

print(f"Clicking at screen ({screen_x}, {screen_y})")
win32api.SetCursorPos((screen_x, screen_y))
time.sleep(0.2)
win32api.mouse_event(win32con.MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0)
time.sleep(0.1)
win32api.mouse_event(win32con.MOUSEEVENTF_LEFTUP, 0, 0, 0, 0)
time.sleep(1.5)

# Screenshot region of the Godot window
shot_path = r"C:\Users\Administrator\AppData\Local\Temp\click_test_after.png"
ps_cmd = f'powershell -ExecutionPolicy Bypass -File E:/C_Moved/IDE/.kimi-code/skills/screenshot/scripts/take_screenshot.ps1 -Path "{shot_path}" -Region {wx},{wy+30},{rect[2]-wx},{rect[3]-wy-30}'
os.system(ps_cmd)
print(f"Screenshot saved to {shot_path}")

proc.terminate()
print("Done")
