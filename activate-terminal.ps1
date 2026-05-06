Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  public class Win32 {
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
  }
"@

$wt = Get-Process -Name "WindowsTerminal" -ErrorAction SilentlyContinue | Select-Object -First 1
if ($wt -and $wt.MainWindowHandle -ne 0) {
  $hwnd = $wt.MainWindowHandle
  [Win32]::ShowWindow($hwnd, 9) | Out-Null
  [Win32]::BringWindowToTop($hwnd) | Out-Null
  [Win32]::SetForegroundWindow($hwnd) | Out-Null
  Write-Host "Activated Windows Terminal"
} else {
  Write-Host "Windows Terminal not found"
}
