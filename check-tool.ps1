param(
    [string]$Action
)

$ErrorActionPreference = "Continue"

# Log directory
$logDir = Join-Path $env:TEMP "claude-pet"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}
$logFile = Join-Path $logDir "check-tool.log"

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$toolName = $env:CLAUDE_TOOL_NAME

# Default state is working
$state = "working"

# Check if this is an interactive tool
if ($toolName -eq "AskUserQuestion" -or $toolName -eq "AskUserQuestion_Guest") {
    $state = "waiting"
}

# Write to log
$logLine = "[$timestamp] Action=$Action Tool=$toolName State=$state"
[System.IO.File]::AppendAllText($logFile, $logLine + "`r`n")
Write-Host "[Pet] $logLine"

# Get current directory hash
$cwd = (Get-Location).ToString()
$hash = [System.BitConverter]::ToString(
    [System.Security.Cryptography.MD5]::Create().ComputeHash(
        [System.Text.Encoding]::UTF8.GetBytes($cwd.ToLower())
    )
).Replace("-", "").Substring(0, 16)

$mappingFile = Join-Path $logDir "cwd_$hash.json"

if (Test-Path $mappingFile) {
    $port = (Get-Content $mappingFile | ConvertFrom-Json).port
    $url = "http://localhost:$port/$state"
    [System.IO.File]::AppendAllText($logFile, "Calling: $url`r`n")
    try {
        Invoke-RestMethod -Uri $url -TimeoutSec 2 | Out-Null
    } catch {}
} else {
    # Broadcast to all pets
    3721..3799 | ForEach-Object {
        $p = $_
        if (netstat -ano 2>$null | Select-String ":$p\s" | Select-String "LISTENING") {
            try { Invoke-RestMethod -Uri "http://localhost:$p/$state" -TimeoutSec 1 | Out-Null } catch {}
        }
    }
}
