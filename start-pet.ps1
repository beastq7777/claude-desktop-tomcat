$ErrorActionPreference = "SilentlyContinue"

# 检查猫咪是否已运行
$response = Invoke-WebRequest -Uri "http://localhost:3721/status" -UseBasicParsing -TimeoutSec 2

if (-not $response) {
    # 启动猫咪
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c cd /d E:\check_status\claude-pet && npm start" -WindowStyle Hidden
    Start-Sleep -Seconds 4
}

# 发送启动命令
Invoke-WebRequest -Uri "http://localhost:3721/start" -UseBasicParsing -TimeoutSec 2 | Out-Null
