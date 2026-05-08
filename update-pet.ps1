param(
  [string]$Action
)

$ErrorActionPreference = "SilentlyContinue"

# Get current working directory as unique identifier
$cwd = Get-Location
$cwdPath = $cwd.ToString()

# Create a simple hash for the directory path (same method as start-pet.ps1)
$md5 = [System.Security.Cryptography.MD5]::Create()
$bytes = [System.Text.Encoding]::UTF8.GetBytes($cwdPath.ToLower())
$hashBytes = $md5.ComputeHash($bytes)
$cwdHash = [System.BitConverter]::ToString($hashBytes).Replace("-", "").Substring(0, 16)

Write-Host "[Pet] Working directory: $cwdPath"
Write-Host "[Pet] Directory hash: $cwdHash"

# Find mapping file
$mappingDir = $env:TEMP + "\claude-pet"
$mappingFile = $mappingDir + "\cwd_$cwdHash.json"

if (Test-Path $mappingFile) {
    # Found mapping for this directory
    $mapping = Get-Content $mappingFile -Raw | ConvertFrom-Json
    $port = $mapping.port

    Write-Host "[Pet] Found pet on port $port, sending $Action"

    try {
        $null = Invoke-WebRequest -Uri "http://localhost:$port/$Action" -UseBasicParsing -TimeoutSec 2
    } catch {
        Write-Host "[Pet] Failed to connect to port $port, removing mapping"
        Remove-Item $mappingFile -Force
    }
} else {
    # No mapping found for this directory
    if ($Action -eq "done") {
        # For 'done' action, send to all listening pets to ensure they stop
        Write-Host "[Pet] No mapping found, sending $Action to all pets"
        $basePort = 3721
        for ($port = $basePort; $port -lt 3800; $port++) {
            $inUse = netstat -ano | Select-String ":$port\s" | Select-String "LISTENING"
            if ($inUse) {
                try {
                    $null = Invoke-WebRequest -Uri "http://localhost:$port/$Action" -UseBasicParsing -TimeoutSec 1
                    Write-Host "[Pet] Sent $Action to port $port"
                } catch { }
            }
        }
    } else {
        Write-Host "[Pet] No pet found for this directory"
    }
}
