param(
  [string]$Action
)

$ErrorActionPreference = "SilentlyContinue"

# Read mapping file
$mappingFile = $env:TEMP + "\claude-pet-mapping.json"

if (-not (Test-Path $mappingFile)) {
    exit
}

# Parse JSON
$json = Get-Content $mappingFile -Raw
$mapping = $json | ConvertFrom-Json

# Start from current process and walk up the process tree
$currentId = $PID
$maxDepth = 15

for ($i = 0; $i -lt $maxDepth; $i++) {
    $idStr = $currentId.ToString()
    
    # Check each property in the mapping object
    foreach ($prop in $mapping.PSObject.Properties) {
        if ($prop.Name -eq $idStr) {
            $entry = $prop.Value
            $port = $entry.port
            $null = Invoke-WebRequest -Uri "http://localhost:$port/$Action" -UseBasicParsing -TimeoutSec 2
            exit
        }
    }
    
    # Get parent process ID
    try {
        $proc = Get-CimInstance Win32_Process -Filter "ProcessId = $currentId" -ErrorAction SilentlyContinue
        if ($proc -and $proc.ParentProcessId -and $proc.ParentProcessId -ne $currentId) {
            $currentId = $proc.ParentProcessId
        } else {
            break
        }
    } catch {
        break
    }
}
