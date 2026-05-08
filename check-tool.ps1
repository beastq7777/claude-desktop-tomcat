param(
  [string]$Action
)

$ErrorActionPreference = "SilentlyContinue"

# 创建日志目录
$logDir = $env:TEMP + "\claude-pet"
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir | Out-Null
}
$logFile = $logDir + "\debug-env.log"

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# 记录所有 CLAUDE_ 相关的环境变量
$claudeEnvVars = Get-ChildItem Env: | Where-Object { $_.Name -like "*CLAUDE*" -or $_.Name -like "*TOOL*" }

$logContent = "[$timestamp] Action: $Action`n"
$logContent += "CLAUDE Environment Variables:`n"

foreach ($var in $claudeEnvVars) {
    $logContent += "  $($var.Name) = $($var.Value)`n"
}

# 特别记录我们关心的变量
$toolName = $env:CLAUDE_TOOL_NAME
$toolInput = $env:CLAUDE_TOOL_INPUT

$logContent += "`nParsed Values:`n"
$logContent += "  Tool Name: $toolName`n"
$logContent += "  Tool Input: $toolInput`n"
$logContent += "========================================`n"

$logContent | Out-File $logFile -Append
Write-Host "[Debug] Tool: $toolName, Action: $Action"

# 检查是否是需要用户交互的工具
$interactiveTools = @('AskUserQuestion', 'AskUserQuestion_Guest')

# 决定要发送的状态
$stateToSend = "working"  # 默认 working
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

$mappingDir = $env:TEMP + "\claude-pet"
$mappingFile = $mappingDir + "\cwd_$cwdHash.json"

if (Test-Path $mappingFile) {
    $mapping = Get-Content $mappingFile -Raw | ConvertFrom-Json
    $port = $mapping.port

    try {
        $null = Invoke-WebRequest -Uri "http://localhost:$port/$stateToSend" -UseBasicParsing -TimeoutSec 2
        Write-Host "[Pet] Sent $stateToSend to port $port"
    } catch {
        Write-Host "[Pet] Failed to connect to port $port"
    }
} else {
    # 没有找到映射，发送到所有监听的宠物
    $basePort = 3721
    for ($port = $basePort; $port -lt 3800; $port++) {
        $inUse = netstat -ano | Select-String ":$port\s" | Select-String "LISTENING"
        if ($inUse) {
            try {
                $null = Invoke-WebRequest -Uri "http://localhost:$port/$stateToSend" -UseBasicParsing -TimeoutSec 1
            } catch { }
        }
    }
}
