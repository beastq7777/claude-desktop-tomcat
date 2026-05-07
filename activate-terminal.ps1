param(
  [string]$hwnd
)

Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  public class Win32 {
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr hWnd);
  }
"@

if ($hwnd) {
  # Use the passed window handle
  $hwndInt = [int64]::Parse($hwnd)
  $hwndPtr = [IntPtr]($hwndInt)
  $exists = [Win32]::IsWindow($hwndPtr)

  if ($exists) {
    [Win32]::ShowWindow($hwndPtr, 9) | Out-Null
    [Win32]::BringWindowToTop($hwndPtr) | Out-Null
    [Win32]::SetForegroundWindow($hwndPtr) | Out-Null
    Write-Host "Activated window with hwnd: $hwnd"
  } else {
    Write-Host "Window not found: $hwnd"
  }
} else {
  # Fallback: find Windows Terminal
  $wt = Get-Process -Name "WindowsTerminal" -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($wt -and $wt.MainWindowHandle -ne 0) {
    $hwndPtr = $wt.MainWindowHandle
    [Win32]::ShowWindow($hwndPtr, 9) | Out-Null
    [Win32]::BringWindowToTop($hwndPtr) | Out-Null
    [Win32]::SetForegroundWindow($hwndPtr) | Out-Null
    Write-Host "Activated Windows Terminal"
  } else {
    Write-Host "Windows Terminal not found"
  }
}
