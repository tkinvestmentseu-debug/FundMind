# fundmind-expo-direct.ps1
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir     = "$projectRoot\logs"
$logFile     = "$logsDir\expo-direct.log"

function Log($m){ $t=Get-Date -Format s; Write-Host "[DirectExpo] $m"; "$t $m" | Out-File $logFile -Encoding UTF8 -Append }

try {
  Set-Location $projectRoot
  Log "Starting Metro via direct node call (bypassing cross-spawn)"

  # Ścieżka do lokalnego CLI
  $expoCli = Join-Path $projectRoot "node_modules\expo\bin\cli.js"
  if (!(Test-Path $expoCli)) { throw "Expo CLI not found at $expoCli" }

  # Wprost wywołanie node na CLI
  & node $expoCli start --tunnel
}
catch {
  Log "ERROR: $_"
  exit 1
}
