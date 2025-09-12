# fundmind-fix-and-publish.ps1 (Anti-Errors up to #46)

$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir     = "$projectRoot\logs"
$errorsLog   = "$logsDir\errors.log"

function Log-Info($m){ $t=Get-Date -Format s; Write-Host "[Publish] $m"; "$t [Info] $m" | Out-File "$logsDir\publish.log" -Encoding UTF8 -Append }
function Log-Error($m){ $t=Get-Date -Format s; Write-Host "[Publish-Error] $m"; "$t [AntiError] $m" | Out-File $errorsLog -Encoding UTF8 -Append }

function Remove-BOM($path){
  if (Test-Path $path){
    $raw = Get-Content $path -Raw -Encoding Byte
    if ($raw.Length -ge 3 -and $raw[0] -eq 239 -and $raw[1] -eq 187 -and $raw[2] -eq 191){
      $clean = $raw[3..($raw.Length-1)]
      [IO.File]::WriteAllBytes($path,$clean)
      Log-Info "Removed BOM from $(Split-Path $path -Leaf)"
    }
  }
}

try {
  Set-Location $projectRoot
  Log-Info "Start fix + publish"

  # 1) babel.config.js (SDK50 safe)
  $babelFile = Join-Path $projectRoot "babel.config.js"
  $fixed = 'module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["react-native-reanimated/plugin"] }; };'
  Set-Content -Path $babelFile -Encoding UTF8 -Value $fixed
  Log-Info "babel.config.js ensured (no expo-router/babel)"

  # 2) Sanitize app.json
  $appFile = Join-Path $projectRoot "app.json"
  if (!(Test-Path $appFile)) { throw "app.json not found" }
  $app = Get-Content $appFile -Raw | ConvertFrom-Json
  if (-not $app.expo){ $app | Add-Member -Name expo -MemberType NoteProperty -Value (@{}) }
  $app.expo.name  = "FundMind"
  $app.expo.slug  = "fundmind"
  $app.expo.owner = "tomasz77"
  $app.expo.sdkVersion = "50.0.0"
  $app.expo.runtimeVersion = @{ policy = "sdkVersion" }
  # projectId – zachowaj, jeśli istnieje; nie nadpisuj losowym
  ($app | ConvertTo-Json -Depth 10) | Set-Content -Path $appFile -Encoding UTF8
  Remove-BOM $appFile
  Log-Info "app.json sanitized"

  # 3) Sanitize package.json
  $pkgFile = Join-Path $projectRoot "package.json"
  if (!(Test-Path $pkgFile)) { throw "package.json not found" }
  $pkg = Get-Content $pkgFile -Raw | ConvertFrom-Json
  if (-not $pkg.dependencies){ $pkg | Add-Member -Name dependencies -MemberType NoteProperty -Value (@{}) }
  if (-not $pkg.devDependencies){ $pkg | Add-Member -Name devDependencies -MemberType NoteProperty -Value (@{}) }

  $pkg.dependencies.expo       = "~50.0.0"
  $pkg.dependencies."expo-router" = "~3.4.10"
  $pkg.dependencies.react      = "18.2.0"
  $pkg.dependencies."react-dom"= "18.2.0"
  $pkg.dependencies."react-native" = "0.73.6"
  $pkg.dependencies."react-native-screens" = "3.29.0"
  $pkg.dependencies."react-native-safe-area-context" = "4.8.2"
  $pkg.dependencies."react-native-gesture-handler" = "2.12.0"
  $pkg.dependencies."react-native-reanimated" = "3.6.0"
  $pkg.dependencies."@react-navigation/native" = "6.1.18"
  $pkg.dependencies."@react-navigation/drawer"= "6.5.8"

  if ($pkg.dependencies.PSObject.Properties.Name -contains "react-test-renderer"){
    $pkg.dependencies.PSObject.Properties.Remove("react-test-renderer")
  }
  $pkg.devDependencies."react-test-renderer" = "18.2.0"
  $pkg.main = "expo-router/entry"
  $pkg.name = "fundmind"

  if ($pkg.PSObject.Properties.Name -contains "overrides"){
    $pkg.PSObject.Properties.Remove("overrides")
    Log-Info "Removed npm overrides"
  }

  ($pkg | ConvertTo-Json -Depth 20) | Set-Content -Path $pkgFile -Encoding UTF8
  Remove-BOM $pkgFile
  Log-Info "package.json sanitized"

  # 4) Clean install
  if (Test-Path "$projectRoot\node_modules"){ Remove-Item -Recurse -Force "$projectRoot\node_modules" }
  if (Test-Path "$projectRoot\package-lock.json"){ Remove-Item -Force "$projectRoot\package-lock.json" }
  Log-Info "npm install (legacy-peer-deps)"
  npm install --legacy-peer-deps
  if ($LASTEXITCODE -ne 0){ Log-Error "npm install failed"; exit 1 }

  # 5) Ensure expo-updates
  Log-Info "Ensuring expo-updates"
  npx expo install expo-updates
  if ($LASTEXITCODE -ne 0){ Log-Error "expo install expo-updates failed"; exit 1 }

  # 6) EAS login
  Log-Info "Check EAS login"
  npx eas-cli whoami
  if ($LASTEXITCODE -ne 0){ npx eas-cli login; if ($LASTEXITCODE -ne 0){ Log-Error "eas login failed"; exit 1 } }

  # 7) Publish update
  Log-Info "Publishing with eas update"
  npx eas-cli update --branch main --message "FundMind publish SDK50 fixed"
  if ($LASTEXITCODE -ne 0){ Log-Error "eas update failed"; exit 1 }

  Log-Info "Completed successfully. Open Expo Go and scan QR."
}
catch {
  Log-Error "Exception: $_"
  exit 1
}
