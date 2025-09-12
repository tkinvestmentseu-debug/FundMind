# fundmind-expo-tunnel-fix.ps1
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir     = "$projectRoot\logs"
$logFile     = "$logsDir\expo-tunnel.log"

function Log($m){ $t=Get-Date -Format s; Write-Host "[Tunnel] $m"; "$t $m" | Out-File $logFile -Encoding UTF8 -Append }

try {
  Set-Location $projectRoot
  Log "Cleaning Metro cache + forcing tunnel mode"

  # 1) Wyczyść cache Metro
  if (Test-Path "$projectRoot\.expo"){ Remove-Item -Recurse -Force "$projectRoot\.expo" }
  if (Test-Path "$projectRoot\.expo-shared"){ Remove-Item -Recurse -Force "$projectRoot\.expo-shared" }

  # 2) Ustaw zmienne środowiskowe
  $env:EXPO_NO_USE_MANIFEST = "1"
  $env:REACT_NATIVE_PACKAGER_HOSTNAME = "localhost"
  $env:EXPO_USE_DEV_SERVER = "1"

  # 3) Start Metro przez tunel
  Log "Starting Metro with tunnel..."
  npx expo start --tunnel
}
catch {
  Log "ERROR: $_"
  exit 1
}
