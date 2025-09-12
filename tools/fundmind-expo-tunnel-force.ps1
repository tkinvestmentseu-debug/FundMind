# fundmind-expo-tunnel-force.ps1
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir     = "$projectRoot\logs"
$logFile     = "$logsDir\expo-tunnel-force.log"

function Log($m){ $t=Get-Date -Format s; Write-Host "[TunnelForce] $m"; "$t $m" | Out-File $logFile -Encoding UTF8 -Append }

try {
  Set-Location $projectRoot
  $cmdPath = "$env:SystemRoot\System32\cmd.exe"
  if (!(Test-Path $cmdPath)) { throw "cmd.exe not found at $cmdPath" }
  $env:COMSPEC = $cmdPath
  Log "Set COMSPEC = $cmdPath"

  # Clean Metro cache
  if (Test-Path "$projectRoot\.expo"){ Remove-Item -Recurse -Force "$projectRoot\.expo" }
  if (Test-Path "$projectRoot\.expo-shared"){ Remove-Item -Recurse -Force "$projectRoot\.expo-shared" }

  Log "Starting Metro via cmd.exe /c expo start --tunnel"
  & $cmdPath "/c" "npx expo start --tunnel"
}
catch {
  Log "ERROR: $_"
  exit 1
}
