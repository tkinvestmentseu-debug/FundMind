param()
$projectRoot = "D:\FundMind"
$logsDir = Join-Path $projectRoot "logs"
$logFile = Join-Path $logsDir "fix-runtime-bridge.log"
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null

function Write-Log($msg) {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  "$ts $msg" | Tee-Object -FilePath $logFile -Append
}

Write-Log "=== Fix runtime bridge start ==="

Set-Location $projectRoot

# 1. Move config files if stuck in app/
$appDir = Join-Path $projectRoot "app"
foreach ($f in "metro.config.js","babel.config.js","tsconfig.json") {
  $src = Join-Path $appDir $f
  $dst = Join-Path $projectRoot $f
  if (Test-Path $src) {
    Write-Log "Moving $f from app/ to root"
    Move-Item -Force $src $dst
  }
}

# 2. Patch package.json
$pkgFile = Join-Path $projectRoot "package.json"
$pkg = Get-Content $pkgFile -Raw | ConvertFrom-Json
$pkg.dependencies.expo = "~50.0.0"
$pkg.dependencies.react = "18.2.0"
$pkg.dependencies."react-native" = "0.73.6"
$pkg.devDependencies."react-test-renderer" = "18.2.0"
$pkg | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $pkgFile
Write-Log "Patched package.json deps"

# 3. Patch app.json
$appJsonFile = Join-Path $projectRoot "app.json"
if (Test-Path $appJsonFile) {
  $appJson = Get-Content $appJsonFile -Raw | ConvertFrom-Json
  if (-not $appJson.expo) { $appJson | Add-Member -NotePropertyName expo -NotePropertyValue (@{}) }
  $appJson.expo.sdkVersion = "50.0.0"
  $appJson | ConvertTo-Json -Depth 10 | Set-Content -Encoding UTF8 $appJsonFile
  Write-Log "Patched app.json sdkVersion"
}

# 4. Clean install
Write-Log "Cleaning node_modules and lock"
Remove-Item -Recurse -Force (Join-Path $projectRoot "node_modules"), (Join-Path $projectRoot "package-lock.json") -ErrorAction SilentlyContinue
npm install | Tee-Object -FilePath $logFile -Append
npx expo install | Tee-Object -FilePath $logFile -Append

# 5. Start Expo
Write-Log "Starting Expo..."
npx expo start --clear --port 8081 --host 192.168.0.16 | Tee-Object -FilePath $logFile -Append