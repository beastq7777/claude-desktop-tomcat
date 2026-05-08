param(
  [string]$Action
)

$ErrorActionPreference = "SilentlyContinue"

# 创建日志目录
$logDir = [System.IO.Path]::Combine($env:TEMP, "claude-pet")
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}
$logFile = [System.IO.Path]::Combine($logDir, "check-tool.log")

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 获取工具名称
$toolName = $env:CLAUDE_TOOL_NAME

# 写日志
Add-Content -Path $logFile -Value "[$timestamp] Action: $Action, Tool: $toolName"

Write-Host "[Pet] Tool: $toolName, Action: $Action"

# 检查是否是需要用户交互的工具
$interactiveTools = @('AskUserQuestion', 'AskUserQuestion_Guest')

# 决定要发送的状态
$stateToSend = "working"
if ($interactiveTools -contains $toolName) {
    $stateToSend = "waiting"
    Write-Host "[Pet] Interactive tool detected, switching to waiting state"
}

# 获取当前工作目录
$cwd = Get-Location
$cwdPath = $cwd.ToString()

$md5 = [System.Security.Cryptography.MD5]::Create()
$bytes = [System.Text.Encoding]::UTF8.GetBytes($cwdPath.ToLower())
$hashBytes = $md5.ComputeHash($bytes)
$cwdHash = [System.BitConverter]::ToString($hashBytes).Replace("-", "").Substring(0, 16)

$mappingDir = [System.IO.Path]::Combine($env:TEMP, "claude-pet")
$mappingFile = [System.IO.Path]::Combine($mappingDir, "cwd_$cwdHash.json")

if (Test-Path $mappingFile) {
    $mapping = Get-Content $mappingFile -Raw | ConvertFrom-Json
    $port = $mapping.port

    try {
        Invoke-RestMethod -Uri "http://localhost:$port/$stateToSend" -TimeoutSec 2 | Out-Null
    } catch { }
} else {
    # 没有找到映射，发送到所有监听的宠物
    $basePort = 3721
    for ($port = $basePort; $port -lt 3800; $port++) {
        $inUse = netstat -ano | Select-String ":$port\s" | Select-String "LISTENING"
        if ($inUse) {
            try {
                Invoke-RestMethod -Uri "http://localhost:$port/$stateToSend" -TimeoutSec 1 | Out-Null
            } catch { }
        }
    }
}
