Write-Host "[Step] Fix-21 start"
$projectRoot = "D:\FundMind"
$logsDir = "$projectRoot\logs"
if (!(Test-Path $logsDir)) { New-Item -ItemType Directory -Force -Path $logsDir | Out-Null }

# babel.config.js
$babelFile = Join-Path $projectRoot "babel.config.js"
if (!(Test-Path $babelFile)) {
Set-Content -Path $babelFile -Encoding UTF8 -Value 'module.exports = function(api) { api.cache(true); return { presets: ["babel-preset-expo"], plugins: ["expo-router/babel"] }; };'
Write-Host "Created babel.config.js"
} else { Write-Host "babel.config.js already exists" }

# metro.config.js
$metroFile = Join-Path $projectRoot "metro.config.js"
if (!(Test-Path $metroFile)) {
Set-Content -Path $metroFile -Encoding UTF8 -Value 'const { getDefaultConfig } = require("expo/metro-config"); const config = getDefaultConfig(__dirname); module.exports = config;'
Write-Host "Created metro.config.js"
} else { Write-Host "metro.config.js already exists" }

Write-Host "`n[Diagnose v2]"
$pkgFile = Join-Path $projectRoot "package.json"
if (Test-Path $pkgFile) {
  $pkg = Get-Content $pkgFile | ConvertFrom-Json
  $pkg.dependencies.PSObject.Properties | ForEach-Object {
    if ($_.Name -match "react" -or $_.Name -eq "react-native") {
      Write-Host "$($_.Name): $($_.Value)"
    }
  }
}
if (Test-Path $babelFile) { Write-Host "babel.config.js check OK" } else { Write-Host "babel.config.js missing" }
if (Test-Path $metroFile) { Write-Host "metro.config.js check OK" } else { Write-Host "metro.config.js missing" }

$appDir = Join-Path $projectRoot "app"
if (Test-Path $appDir) { Get-ChildItem $appDir -Recurse -Name } else { Write-Host "app folder missing" }

Write-Host "`n=== Done ==="
