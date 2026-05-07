$ErrorActionPreference = "SilentlyContinue"

# Function to get process tree (current process and all ancestors)
function Get-ProcessTree {
    $result = @()
    $currentProcessId = $PID
    $maxDepth = 15
    
    for ($i = 0; $i -lt $maxDepth; $i++) {
        $result += $currentProcessId
        try {
            $proc = Get-CimInstance Win32_Process -Filter "ProcessId = $currentProcessId" -ErrorAction SilentlyContinue
            if ($proc -and $proc.ParentProcessId -and $proc.ParentProcessId -ne $currentProcessId) {
                $currentProcessId = $proc.ParentProcessId
            } else {
                break
            }
        } catch {
            break
        }
    }
    return $result
}

# Get current active window handle (the terminal running Claude)
Add-Type @"
  using System;
  using System.Runtime.InteropServices;
  public class Win32 {
    [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);
  }
"@
$hwnd = [Win32]::GetForegroundWindow()
$hwndValue = $hwnd.ToInt64()

# Get the process ID of the terminal window
$terminalPid = 0
[Win32]::GetWindowThreadProcessId($hwnd, [ref]$terminalPid) | Out-Null

# Get all PIDs in current process tree
$processTree = Get-ProcessTree

Write-Host "[Pet] Terminal PID: $terminalPid"
Write-Host "[Pet] Process tree: $($processTree -join ' -> ')"

# Scan for available port (starting from 3721)
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

Write-Host "[Pet] Starting cat #$catNumber on port $availablePort, hwnd: $hwndValue"

# Save mapping for ALL PIDs in the process tree
$mappingFile = $env:TEMP + "\claude-pet-mapping.json"

# Read existing mapping (PowerShell 5.1 compatible)
$existingMapping = @{}
if (Test-Path $mappingFile) {
    try {
        $json = Get-Content $mappingFile -Raw
        $parsed = $json | ConvertFrom-Json
        foreach ($prop in $parsed.PSObject.Properties) {
            $existingMapping[$prop.Name] = $prop.Value
        }
    } catch {}
}

# Remove old entries for this port (cleanup)
$keysToRemove = @()
foreach ($key in $existingMapping.Keys) {
    $entry = $existingMapping[$key]
    if ($entry.port -eq $availablePort) {
        $keysToRemove += $key
    }
}
foreach ($key in $keysToRemove) {
    $existingMapping.Remove($key)
}

# Create new entry
$newEntry = @{
    port = $availablePort
    hwnd = $hwndValue
}

# Add mapping for each PID in the process tree
foreach ($processId in $processTree) {
    $existingMapping[$processId.ToString()] = $newEntry
}

# Also add terminal PID
if ($terminalPid -and -not $existingMapping.ContainsKey($terminalPid.ToString())) {
    $existingMapping[$terminalPid.ToString()] = $newEntry
}

# Save mapping
$existingMapping | ConvertTo-Json -Depth 2 | Set-Content $mappingFile

Write-Host "[Pet] Saved mapping for $($processTree.Count) PIDs + terminal -> port=$availablePort"

# Start Electron app with port and hwnd parameters
$appPath = "E:\coding\claude-desktop-tomcat\claude-pet"
$electronExe = $appPath + "\node_modules\electron\dist\electron.exe"
$args = '"' + $appPath + '" --port=' + $availablePort + ' --hwnd=' + $hwndValue

Start-Process -FilePath $electronExe -ArgumentList $args

# Wait for app to start
Start-Sleep -Seconds 2

# Send start command to the port
$null = Invoke-WebRequest -Uri "http://localhost:$availablePort/start" -UseBasicParsing -TimeoutSec 2
