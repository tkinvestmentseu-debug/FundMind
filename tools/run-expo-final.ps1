$ErrorActionPreference = "Stop"

$projectRoot = "D:\FundMind"
$logsDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir | Out-Null }

$pkgPath = Join-Path $projectRoot "package.json"

# Strip BOM if present
[byte[]]$bytes = [System.IO.File]::ReadAllBytes($pkgPath)
if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $clean = $bytes[3..($bytes.Length-1)]
    [System.IO.File]::WriteAllBytes($pkgPath, $clean)
    Write-Output "[run-expo-final] BOM stripped from package.json"
} else {
    Write-Output "[run-expo-final] No BOM found in package.json"
}

# Start Expo
$expoLog = Join-Path $logsDir ("expo-run-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
$cmd = "/c npx expo start --clear --tunnel > `"$expoLog`" 2>>&1"
Write-Output "[run-expo-final] Starting Expo (logging to $expoLog)..."

Start-Process -FilePath "cmd.exe" -ArgumentList $cmd -NoNewWindow
