$ErrorActionPreference = "SilentlyContinue"

# Get foreground window handle (the terminal running this script)
Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  public class Win32 {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  }
"@
$hwnd = [Win32]::GetForegroundWindow()
$hwndValue = $hwnd.ToInt64()

# Get current working directory as unique identifier
$cwd = Get-Location
$cwdPath = $cwd.ToString()

# Create a simple hash for the directory path (for filename)
$md5 = [System.Security.Cryptography.MD5]::Create()
$bytes = [System.Text.Encoding]::UTF8.GetBytes($cwdPath.ToLower())
$hashBytes = $md5.ComputeHash($bytes)
$cwdHash = [System.BitConverter]::ToString($hashBytes).Replace("-", "").Substring(0, 16)

Write-Host "[Pet] Working directory: $cwdPath"
Write-Host "[Pet] Directory hash: $cwdHash"

# Check if a pet already exists for THIS directory
$mappingDir = $env:TEMP + "\claude-pet"
$mappingFile = $mappingDir + "\cwd_$cwdHash.json"

if (Test-Path $mappingFile) {
    # Read existing mapping
    $mapping = Get-Content $mappingFile -Raw | ConvertFrom-Json
    $existingPort = $mapping.port

    # Check if the port for THIS directory's pet is still listening
    $portListening = netstat -ano | Select-String ":$existingPort\s" | Select-String "LISTENING"

    if ($portListening) {
        Write-Host "[Pet] Cat already running on port $existingPort for this directory, reusing"

        # Update hwnd in mapping
        $mapping.hwnd = $hwndValue
        $mapping | ConvertTo-Json | Set-Content $mappingFile

        # Send start command to existing pet
        try {
            $null = Invoke-WebRequest -Uri "http://localhost:$existingPort/start" -UseBasicParsing -TimeoutSec 2
        } catch {}

        exit
    } else {
        Write-Host "[Pet] Existing pet on port $existingPort is gone, starting new one"
        Remove-Item $mappingFile -Force
    }
}

# Find next available port
$basePort = 3721
$availablePort = $basePort

while ($availablePort -lt 3800) {
    $inUse = netstat -ano | Select-String ":$availablePort\s" | Select-String "LISTENING"
    if (-not $inUse) {
        break
    }
    $availablePort++
}

# Cat number = port - 3721 + 1
$catNumber = $availablePort - $basePort + 1

Write-Host "[Pet] Starting cat #$catNumber on port $availablePort"

# Create mapping directory if not exists
if (-not (Test-Path $mappingDir)) {
    New-Item -ItemType Directory -Path $mappingDir | Out-Null
}

# Write mapping file
$mapping = @{
    port = $availablePort
    cwd = $cwdPath
    hwnd = $hwndValue
}
$mapping | ConvertTo-Json | Set-Content $mappingFile

Write-Host "[Pet] Saved mapping: $mappingFile"

# Start Electron app with port and hwnd parameters
$appPath = "E:\coding\claude-desktop-tomcat\claude-pet"
$electronExe = $appPath + "\node_modules\electron\dist\electron.exe"
$args = '"' + $appPath + '" --port=' + $availablePort + ' --hwnd=' + $hwndValue

Start-Process -FilePath $electronExe -ArgumentList $args

# Wait for app to start
Start-Sleep -Seconds 2

# Send start command to the port
$null = Invoke-WebRequest -Uri "http://localhost:$availablePort/start" -UseBasicParsing -TimeoutSec 2

Write-Host "[Pet] Cat #$catNumber started!"
