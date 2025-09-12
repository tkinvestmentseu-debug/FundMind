# fundmind-start-expo-go.ps1 — start w Expo Go (SDK 49), bez tunelu
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir     = "$projectRoot\logs"
$logFile     = "$logsDir\start-expo-go.log"

function Log($m){ $t=Get-Date -Format s; Write-Host "[StartGo] $m"; "$t $m" | Out-File $logFile -Encoding UTF8 -Append }

try {
  Set-Location $projectRoot
  Log "Start dev server in Expo Go mode (LAN)"

  # Krótki sanity check SDK
  $app = Get-Content "app.json" -Raw | ConvertFrom-Json
  if ($app.expo.sdkVersion -ne "49.0.0") {
    Log "Warning: app.json sdkVersion=$($app.expo.sdkVersion) (dla Expo Go najlepiej 49.0.0)"
  }

  # Wymuś Expo Go i LAN (bez tunelu)
  npx expo start --go --lan
  if ($LASTEXITCODE -ne 0) {
    Log "Fallback: ponawiam tylko z --go"
    npx expo start --go
  }
}
catch {
  Log "ERROR: $_"
  exit 1
}
