param()

$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$toolsDir = Join-Path $projectRoot "tools"
$logsDir = Join-Path $projectRoot "logs"

# 1. Fix shim (idempotent)
$fixShim = Join-Path $toolsDir "fix-metro-shim.ps1"
if (Test-Path $fixShim) {
    Write-Output "[run-expo] Running shim fix..."
    & pwsh -File $fixShim
} else {
    Write-Output "[run-expo] Warning: fix-metro-shim.ps1 not found, skipping."
}

# 2. Start Expo with tunnel + clear
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logsDir "expo-$timestamp.log"

Write-Output "[run-expo] Starting Expo at $projectRoot"
Write-Output "[run-expo] Log file: $logFile"

Set-Location $projectRoot
& npx expo start --clear --tunnel *>&1 | Tee-Object -FilePath $logFile
