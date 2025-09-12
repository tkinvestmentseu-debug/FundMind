$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$toolsDir = Join-Path $projectRoot "tools"
$shimFile = Join-Path $toolsDir "metro-sourcemap-shim.js"
$metroConfig = Join-Path $projectRoot "metro.config.js"

if (-not (Test-Path $toolsDir)) {
    New-Item -ItemType Directory -Path $toolsDir | Out-Null
}

# Tworzymy shim
$shimCode = "function getSourceMapURL() {`n  return null;`n}`nmodule.exports = { getSourceMapURL };"
Set-Content -Path $shimFile -Value $shimCode -Encoding UTF8

# Patch metro.config.js
if (Test-Path $metroConfig) {
    $content = Get-Content $metroConfig -Raw
    if ($content -notmatch "metro-sourcemap-shim") {
        $insert = "const metroShim = require('./tools/metro-sourcemap-shim');"
        $patched = $insert + "`r`n" + $content
        Set-Content -Path $metroConfig -Value $patched -Encoding UTF8
        Write-Output "[fix-shim] Patched metro.config.js"
    } else {
        Write-Output "[fix-shim] Already patched"
    }
} else {
    $configCode = "const { getDefaultConfig } = require('@expo/metro-config');`nconst config = getDefaultConfig(__dirname);`nconst metroShim = require('./tools/metro-sourcemap-shim');`nmodule.exports = config;"
    Set-Content -Path $metroConfig -Value $configCode -Encoding UTF8
    Write-Output "[fix-shim] Created new metro.config.js"
}

Write-Output "[fix-shim] Shim ready at $shimFile"
