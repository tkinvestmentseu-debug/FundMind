# fundmind-clean-expo-go.ps1 — usuń expo-dev-client i wymuś Expo Go
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir     = "$projectRoot\logs"
$logFile     = "$logsDir\expo-go-fix.log"

function Log($m){ $t=Get-Date -Format s; Write-Host "[ExpoGoFix] $m"; "$t $m" | Out-File $logFile -Encoding UTF8 -Append }

try {
  Set-Location $projectRoot
  Log "Start cleaning project for Expo Go"

  # 1) Usuń expo-dev-client z package.json
  $pkgPath = Join-Path $projectRoot "package.json"
  $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
  if ($pkg.dependencies."expo-dev-client") {
    $pkg.dependencies.PSObject.Properties.Remove("expo-dev-client")
    Log "Removed expo-dev-client from dependencies"
  }
  if ($pkg.devDependencies."expo-dev-client") {
    $pkg.devDependencies.PSObject.Properties.Remove("expo-dev-client")
    Log "Removed expo-dev-client from devDependencies"
  }
  ($pkg | ConvertTo-Json -Depth 20) | Set-Content -Path $pkgPath -Encoding UTF8

  # 2) Usuń śmieci po dev-client w app.json
  $appPath = Join-Path $projectRoot "app.json"
  $app = Get-Content $appPath -Raw | ConvertFrom-Json
  if ($app.expo.PSObject.Properties.Name -contains "plugins") {
    $app.expo.plugins = @($app.expo.plugins | Where-Object { $_ -ne "expo-dev-client" })
    Log "Removed expo-dev-client from app.json plugins"
  }
  ($app | ConvertTo-Json -Depth 10) | Set-Content -Path $appPath -Encoding UTF8

  # 3) Clean node_modules
  if (Test-Path "$projectRoot\node_modules"){ Remove-Item -Recurse -Force "$projectRoot\node_modules" }
  if (Test-Path "$projectRoot\package-lock.json"){ Remove-Item -Force "$projectRoot\package-lock.json" }
  Log "node_modules and lockfile removed"

  # 4) Fresh install
  npm install --legacy-peer-deps
  if ($LASTEXITCODE -ne 0){ throw "npm install failed" }

  # 5) Start Metro w trybie Expo Go
  Log "Starting Metro in Expo Go mode"
  npx expo start --go --lan
}
catch {
  Log "ERROR: $_"
  exit 1
}
