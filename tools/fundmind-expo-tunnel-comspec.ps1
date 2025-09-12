# fundmind-expo-tunnel-comspec.ps1
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir     = "$projectRoot\logs"
$logFile     = "$logsDir\expo-tunnel.log"

function Log($m){ $t=Get-Date -Format s; Write-Host "[TunnelFix] $m"; "$t $m" | Out-File $logFile -Encoding UTF8 -Append }

try {
  Set-Location $projectRoot
  Log "Force COMSPEC to cmd.exe and clean Metro cache"

  # 1) Wymuś COMSPEC na pełną ścieżkę cmd.exe
  $cmdPath = "$env:SystemRoot\System32\cmd.exe"
  if (!(Test-Path $cmdPath)) { throw "cmd.exe not found at $cmdPath" }
  $env:COMSPEC = $cmdPath
  Log "Set COMSPEC = $cmdPath"

  # 2) Wyczyść cache Metro
  if (Test-Path "$projectRoot\.expo"){ Remove-Item -Recurse -Force "$projectRoot\.expo" }
  if (Test-Path "$projectRoot\.expo-shared"){ Remove-Item -Recurse -Force "$projectRoot\.expo-shared" }

  # 3) Start Metro w trybie tunelu
  Log "Starting Metro with tunnel (Expo Go ready)"
  npx expo start --tunnel
}
catch {
  Log "ERROR: $_"
  exit 1
}
