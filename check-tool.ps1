param(
  [string]$Action
)

$ErrorActionPreference = "SilentlyContinue"

# 获取工具名称
$toolName = $env:CLAUDE_TOOL_NAME

Write-Host "[Pet] Tool: $toolName, Action: $Action"

# 检查是否是需要用户交互的工具
$interactiveTools = @('AskUserQuestion', 'AskUserQuestion_Guest')

if ($interactiveTools -contains $toolName) {
    # 需要用户交互，切换到 waiting 状态
    $Action = "waiting"
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
        $null = Invoke-WebRequest -Uri "http://localhost:$port/$Action" -UseBasicParsing -TimeoutSec 2
        Write-Host "[Pet] Sent $Action to port $port"
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
                $null = Invoke-WebRequest -Uri "http://localhost:$port/$Action" -UseBasicParsing -TimeoutSec 1
            } catch { }
        }
    }
}
