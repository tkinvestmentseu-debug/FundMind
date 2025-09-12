$ErrorActionPreference = "Stop"

function Ensure-Dir { param([string]$p) if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null } }
function Ensure-Dep {
  param([object]$json,[string]$section,[string]$name,[string]$version)
  if ($null -eq $json.$section) { $json | Add-Member -NotePropertyName $section -NotePropertyValue (@{}) }
  if ($null -eq $json.$section.$name) { $json.$section | Add-Member -NotePropertyName $name -NotePropertyValue $version }
  else { $json.$section.$name = $version }
}

$projectRoot = "D:\FundMind"
$toolsDir = Join-Path $projectRoot "tools"
$logsDir = Join-Path $projectRoot "logs"
Ensure-Dir $toolsDir
Ensure-Dir $logsDir

Write-Output "[fix] Uninstall legacy global expo-cli (ignore errors if absent)..."
try { npm uninstall -g expo-cli | Out-Null } catch { }

Write-Output "[fix] Install new global expo..."
try { npm install -g expo | Out-Null } catch { }

# package.json alignment
$pkgPath = Join-Path $projectRoot "package.json"
if (-not (Test-Path $pkgPath)) { throw "package.json not found at $pkgPath" }
$pkgJson = Get-Content $pkgPath -Raw | ConvertFrom-Json
Ensure-Dep $pkgJson "dependencies" "expo-router" "~3.4.7"
Ensure-Dep $pkgJson "dependencies" "@expo/metro-config" "~0.18.9"
Ensure-Dep $pkgJson "devDependencies" "metro" "0.79.1"
$pkgJson | ConvertTo-Json -Depth 40 | Set-Content -Path $pkgPath -Encoding UTF8
Write-Output "[fix] package.json pinned (expo-router, @expo/metro-config, metro)."

# clean install
$nodeModules = Join-Path $projectRoot "node_modules"
$lockFile = Join-Path $projectRoot "package-lock.json"
if (Test-Path $nodeModules) { Write-Output "[fix] Removing node_modules..."; Remove-Item -Recurse -Force $nodeModules }
if (Test-Path $lockFile) { Write-Output "[fix] Removing package-lock.json..."; Remove-Item -Force $lockFile }
Write-Output "[fix] npm install..."
$npmLog = Join-Path $logsDir ("npm-install-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
cmd.exe /c "npm install > `"$npmLog`" 2>>&1"

# shim injection (3 locations)
$shimCode = "function getSourceMapURL() {`n  return null;`n}`nmodule.exports = { getSourceMapURL };"
$shimLocal = Join-Path $toolsDir "metro-sourcemap-shim.js"
Set-Content -Path $shimLocal -Value $shimCode -Encoding UTF8
$nmTools = Join-Path $projectRoot "node_modules\tools"
Ensure-Dir $nmTools
Copy-Item $shimLocal (Join-Path $nmTools "metro-sourcemap-shim.js") -Force
$globalTools = "D:\tools"
Ensure-Dir $globalTools
Copy-Item $shimLocal (Join-Path $globalTools "metro-sourcemap-shim.js") -Force
Write-Output "[fix] Shim injected to tools/, node_modules/tools/, and D:\tools."

# babel.config.js (root)
$babelCfg = Join-Path $projectRoot "babel.config.js"
$babelText = "module.exports = function(api) {`n  api.cache(true);`n  return {`n    presets: ['babel-preset-expo'],`n    plugins: ['expo-router/babel'],`n  };`n};"
Set-Content -Path $babelCfg -Value $babelText -Encoding UTF8
Write-Output "[fix] babel.config.js written."

# start expo with cmd redirection (avoid Start-Process same-file redir error)
$expoLog = Join-Path $logsDir ("expo-fix-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
$arg = "/c npx expo start --clear --tunnel > `"$expoLog`" 2>>&1"
Write-Output "[fix] Starting Expo (logging to $expoLog)..."
Start-Process -FilePath "cmd.exe" -ArgumentList $arg -NoNewWindow

Start-Sleep -Seconds 25
Write-Output ""
Write-Output "--- Last 20 lines of log ---"
Get-Content -Path $expoLog -Tail 20
