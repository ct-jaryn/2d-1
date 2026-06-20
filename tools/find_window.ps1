Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class WinAPI {
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);
  public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
  public struct RECT { public int Left, Top, Right, Bottom; }
}
"@
$sb = New-Object System.Text.StringBuilder(256)
[WinAPI+EnumWindowsProc]$callback = {
  param($hwnd, $lparam)
  if ([WinAPI]::IsWindowVisible($hwnd)) {
    [WinAPI]::GetWindowText($hwnd, $sb, 256) > $null
    $title = $sb.ToString()
    if ($title -like '*Pixel Idle Hero*' -or $title -like '*Godot*') {
      $rect = New-Object WinAPI+RECT
      [WinAPI]::GetWindowRect($hwnd, [ref]$rect) > $null
      Write-Host "HWND: $hwnd Title: $title Rect: ($($rect.Left), $($rect.Top)) - ($($rect.Right), $($rect.Bottom))"
    }
  }
  return $true
}
[WinAPI]::EnumWindows($callback, 0)
