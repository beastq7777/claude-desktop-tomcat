param(
  [string]$Action
)

$ErrorActionPreference = "SilentlyContinue"

# Scan all running pet instances and send command
$basePort = 3721
$maxPort = 3800

for ($port = $basePort; $port -lt $maxPort; $port++) {
  $inUse = netstat -ano | Select-String ":$port\s" | Select-String "LISTENING"
  if ($inUse) {
    try {
      $null = Invoke-WebRequest -Uri "http://localhost:$port/$Action" -UseBasicParsing -TimeoutSec 1
    } catch {
      # Ignore errors
    }
  }
}
