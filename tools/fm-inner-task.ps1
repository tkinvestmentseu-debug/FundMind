# fm-inner-task.ps1 (runs inside child PowerShell)
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot
$env:BROWSER="none"
$env:EXPO_NO_DOCTOR="1"
$env:npm_config_legacy_peer_deps="true"

function Test-Json($p){ if(Test-Path $p){ Get-Content $p -Raw | ConvertFrom-Json | Out-Null } }

# Sanity JSON (bez modyfikacji)
Test-Json ".\package.json"
Test-Json ".\app.json"

# Wersje i ścieżki
Write-Host "node: "
node -v
Write-Host "npm : "
npm -v
where.exe node
where.exe npm
where.exe npx

# Wersje expo/eas
npx expo --version
npx eas-cli --version

# Export (jak przy EAS Update) – tu zwykle pojawiają się realne błędy bundlera/Babela
npx expo export --platform ios --platform android --dump-assetmap --dump-sourcemap
