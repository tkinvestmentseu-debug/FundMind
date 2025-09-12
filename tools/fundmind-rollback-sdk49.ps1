# fundmind-rollback-sdk49.ps1
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir     = "$projectRoot\logs"

function Log($m){ $t=Get-Date -Format s; Write-Host "[Rollback49] $m"; "$t [Info] $m" | Out-File "$logsDir\rollback-sdk49.log" -Encoding UTF8 -Append }

function Remove-BOM($path){
  if (Test-Path $path){
    $raw = Get-Content $path -Raw -Encoding Byte
    if ($raw.Length -ge 3 -and $raw[0] -eq 239 -and $raw[1] -eq 187 -and $raw[2] -eq 191){
      $clean = $raw[3..($raw.Length-1)]
      [IO.File]::WriteAllBytes($path,$clean)
      Log "Removed BOM from $(Split-Path $path -Leaf)"
    }
  }
}

try {
  Set-Location $projectRoot
  Log "Start rollback to SDK 49"

  # --- 1) Fix app.json ---
  $appFile = Join-Path $projectRoot "app.json"
  if (!(Test-Path $appFile)) { throw "app.json not found" }
  $app = Get-Content $appFile -Raw | ConvertFrom-Json
  if (-not $app.expo){ $app | Add-Member -Name expo -MemberType NoteProperty -Value (@{}) }
  $app.expo.sdkVersion = "49.0.0"
  $app.expo.runtimeVersion = @{ policy = "sdkVersion" }
  ($app | ConvertTo-Json -Depth 10) | Set-Content -Path $appFile -Encoding UTF8
  Remove-BOM $appFile
  Log "app.json set to SDK 49"

  # --- 2) Fix package.json ---
  $pkgFile = Join-Path $projectRoot "package.json"
  if (!(Test-Path $pkgFile)) { throw "package.json not found" }
  $pkg = Get-Content $pkgFile -Raw | ConvertFrom-Json
  if (-not $pkg.dependencies){ $pkg | Add-Member -Name dependencies -MemberType NoteProperty -Value (@{}) }
  if (-not $pkg.devDependencies){ $pkg | Add-Member -Name devDependencies -MemberType NoteProperty -Value (@{}) }

  $pkg.dependencies.expo       = "~49.0.21"
  $pkg.dependencies."expo-router" = "~3.4.8"
  $pkg.dependencies.react      = "18.2.0"
  $pkg.dependencies."react-dom"= "18.2.0"
  $pkg.dependencies."react-native" = "0.72.10"
  $pkg.dependencies."@react-navigation/native"  = "6.1.17"
  $pkg.dependencies."@react-navigation/drawer" = "6.6.3"
  $pkg.dependencies."react-native-screens"     = "3.27.0"
  $pkg.dependencies."react-native-safe-area-context" = "4.6.3"
  $pkg.dependencies."react-native-gesture-handler"   = "2.9.0"
  $pkg.dependencies."react-native-reanimated"        = "3.4.2"

  $pkg.devDependencies."react-test-renderer" = "18.2.0"
  $pkg.main = "expo-router/entry"
  $pkg.name = "fundmind"

  ($pkg | ConvertTo-Json -Depth 20) | Set-Content -Path $pkgFile -Encoding UTF8
  Remove-BOM $pkgFile
  Log "package.json downgraded to SDK 49 deps"

  # --- 3) Fix babel.config.js ---
  $babelFile = Join-Path $projectRoot "babel.config.js"
  $fixed = 'module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["react-native-reanimated/plugin"] }; };'
  Set-Content -Path $babelFile -Encoding UTF8 -Value $fixed
  Log "babel.config.js fixed"

  # --- 4) Clean install ---
  if (Test-Path "$projectRoot\node_modules"){ Remove-Item -Recurse -Force "$projectRoot\node_modules" }
  if (Test-Path "$projectRoot\package-lock.json"){ Remove-Item -Force "$projectRoot\package-lock.json" }
  Log "npm install clean"
  npm install
  if ($LASTEXITCODE -ne 0){ throw "npm install failed" }

  Log "Rollback to SDK 49 completed. Run 'npx expo start --tunnel' and scan QR in Expo Go."
}
catch {
  Log "Exception: $_"
  exit 1
}
