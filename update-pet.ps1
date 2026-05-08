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
        Write-Host "[Pet] Failed to connect to port $port, pet may be closed"
        Remove-Item $mappingFile -Force
    }
} else {
    Write-Host "[Pet] No pet found for this directory"
}
