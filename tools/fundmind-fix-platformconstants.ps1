param()
$projectRoot = (Get-Location).Path
$logsDir = Join-Path $projectRoot "logs"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logsDir "fix-platformconstants-$timestamp.log"

function Log($msg) {
  $line = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $msg
  $line | Tee-Object -FilePath $logFile -Append
}

Log "=== Start PlatformConstants fix ==="

# backup package.json and app.json
foreach ($file in @("package.json","app.json")) {
  $path = Join-Path $projectRoot $file
  if (Test-Path $path) {
    $backup = "$path.bak.$timestamp"
    Copy-Item $path $backup -Force
    Log "Backup created: $backup"
  }
}

# clean node_modules and lockfile
foreach ($item in @("node_modules","package-lock.json")) {
  $path = Join-Path $projectRoot $item
  if (Test-Path $path) {
    Remove-Item -Recurse -Force $path
    Log "Removed $item"
  }
}

# fix package.json expo version
$pkgPath = Join-Path $projectRoot "package.json"
if (Test-Path $pkgPath) {
  $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
  $pkg.dependencies.expo = "~50.0.0"
  $pkg.dependencies.react = "18.2.0"
  $pkg.dependencies."react-native" = "0.73.6"
  $pkg.dependencies."react-test-renderer" = "18.2.0"
  $pkg | ConvertTo-Json -Depth 100 | Set-Content -Path $pkgPath -Encoding UTF8
  Log "Patched package.json versions"
}

# fix app.json sdkVersion
$appPath = Join-Path $projectRoot "app.json"
if (Test-Path $appPath) {
  $app = Get-Content $appPath -Raw | ConvertFrom-Json
  if (-not $app.expo.sdkVersion) {
    $app.expo | Add-Member -NotePropertyName "sdkVersion" -NotePropertyValue "50.0.0"
  } else {
    $app.expo.sdkVersion = "50.0.0"
  }
  $app | ConvertTo-Json -Depth 100 | Set-Content -Path $appPath -Encoding UTF8
  Log "Patched app.json sdkVersion"
}

# reinstall
Log "Installing dependencies..."
npm install react@18.2.0 react-native@0.73.6 react-test-renderer@18.2.0 2>&1 | Tee-Object -FilePath $logFile -Append
npx expo install 2>&1 | Tee-Object -FilePath $logFile -Append

# start expo
Log "Starting Expo..."
npx expo start --clear --port 8081 --host 192.168.0.16 2>&1 | Tee-Object -FilePath $logFile -Append
