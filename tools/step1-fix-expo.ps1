# FUNDMIND STEP 1: Stabilizacja Expo (PS7, ASCII-only, idempotent)
$ErrorActionPreference = "Stop"

function Ensure-Dir { param([string]$p) if (-not (Test-Path $p)) { New-Item -ItemType Directory -Path $p | Out-Null } }
function Ensure-Obj { param([object]$o,[string]$n) if (-not ($o.PSObject.Properties.Name -contains $n)) { $o | Add-Member -MemberType NoteProperty -Name $n -Value ([pscustomobject]@{}) } }
function Set-KV    { param([object]$o,[string]$k,[object]$v) $p=$o.PSObject.Properties[$k]; if($p){$p.Value=$v}else{$o|Add-Member NoteProperty $k $v} }
function Del-KV    { param([object]$o,[string]$k) if ($o.PSObject.Properties.Name -contains $k) { $null = $o.PSObject.Properties.Remove($k) } }
function Write-NoBom { param([string]$path,[string]$text) $enc = New-Object System.Text.UTF8Encoding($false); [System.IO.File]::WriteAllText($path,$text,$enc) }
function Strip-BOM-Bytes { param([string]$path) $b=[System.IO.File]::ReadAllBytes($path); if($b.Length -ge 3 -and $b[0]-eq0xEF -and $b[1]-eq0xBB -and $b[2]-eq0xBF){[System.IO.File]::WriteAllBytes($path,$b[3..($b.Length-1)])} }

$root  = "D:\FundMind"
$tools = Join-Path $root "tools"
$logs  = Join-Path $root "logs"
Ensure-Dir $tools; Ensure-Dir $logs

try { npm uninstall -g expo-cli expo | Out-Null } catch { }

$pkgPath = Join-Path $root "package.json"
if (-not (Test-Path $pkgPath)) { throw "package.json not found at $pkgPath" }
Strip-BOM-Bytes $pkgPath
$pkg = (Get-Content $pkgPath -Raw) | ConvertFrom-Json

Ensure-Obj $pkg "dependencies"; Ensure-Obj $pkg "devDependencies"; Ensure-Obj $pkg "overrides"; Ensure-Obj $pkg "scripts"
foreach($k in @("metro","metro-cache","metro-config")){ Del-KV $pkg.dependencies $k; Del-KV $pkg.devDependencies $k }

Set-KV $pkg.dependencies    "expo" "~50.0.0"
Set-KV $pkg.dependencies    "react" "18.2.0"
Set-KV $pkg.dependencies    "react-dom" "18.2.0"
Set-KV $pkg.dependencies    "react-native" "0.73.6"
Set-KV $pkg.dependencies    "react-test-renderer" "18.2.0"
Set-KV $pkg.dependencies    "expo-router" "~3.4.7"
Set-KV $pkg.dependencies    "@expo/metro-config" "~0.18.9"
Set-KV $pkg.devDependencies "metro" "0.79.1"
Set-KV $pkg.devDependencies "@react-native-community/cli" "^11.3.8"
Set-KV $pkg.devDependencies "@react-native-community/cli-server-api" "^11.3.8"
Set-KV $pkg.devDependencies "@react-native-community/cli-platform-android" "^11.3.8"
Set-KV $pkg.devDependencies "@react-native-community/cli-platform-ios" "^11.3.8"
Set-KV $pkg.overrides "metro" "0.79.1"; Set-KV $pkg.overrides "metro-cache" "0.79.1"; Set-KV $pkg.overrides "metro-config" "0.79.1"
Set-KV $pkg "main" "expo-router/entry"
if (-not ($pkg.scripts.start)) { Set-KV $pkg.scripts "start" "expo start -c" }
Write-NoBom $pkgPath ($pkg | ConvertTo-Json -Depth 60); Strip-BOM-Bytes $pkgPath
Write-Output "[step1] package.json pinned & saved (no BOM)."

$appPath = Join-Path $root "app.json"
if (Test-Path $appPath) { Strip-BOM-Bytes $appPath; $app = (Get-Content $appPath -Raw) | ConvertFrom-Json } else { $app = [pscustomobject]@{ expo = [pscustomobject]@{} } }
if (-not $app.expo) { $app | Add-Member NoteProperty expo ([pscustomobject]@{}) }
if (-not $app.expo.plugins) { $app.expo | Add-Member NoteProperty plugins @() }
if (-not ($app.expo.plugins -contains "expo-router")) { $app.expo.plugins += "expo-router" }
if (-not $app.expo.name) { $app.expo | Add-Member NoteProperty name "FundMind" }
if (-not $app.expo.slug) { $app.expo | Add-Member NoteProperty slug "fundmind" }
Write-NoBom $appPath ($app | ConvertTo-Json -Depth 40); Strip-BOM-Bytes $appPath
Write-Output "[step1] app.json ensured (plugin: expo-router)."

$shimCode = "function getSourceMapURL() {`n  return null;`n}`nmodule.exports = { getSourceMapURL };"
$shimLocal = Join-Path $tools "metro-sourcemap-shim.js"; Write-NoBom $shimLocal $shimCode
$targets = @((Join-Path $root "node_modules\tools\metro-sourcemap-shim.js"), "D:\tools\metro-sourcemap-shim.js")
foreach($t in $targets){ $d=Split-Path $t -Parent; Ensure-Dir $d; if($t -ne $shimLocal){ Copy-Item $shimLocal $t -Force } }
Write-Output "[step1] shim injected."

$babelPath = Join-Path $root "babel.config.js"
$babelTxt = "module.exports = function(api) {`n  api.cache(true);`n  return {`n    presets: ['babel-preset-expo'],`n    plugins: ['expo-router/babel'],`n  };`n};"
Write-NoBom $babelPath $babelTxt
Write-Output "[step1] babel.config.js written."

$nm = Join-Path $root "node_modules"; $lock = Join-Path $root "package-lock.json"
if (Test-Path $nm)   { Write-Output "[step1] removing node_modules..."; Remove-Item -Recurse -Force $nm }
if (Test-Path $lock) { Write-Output "[step1] removing package-lock.json..."; Remove-Item -Force $lock }
$npmLog = Join-Path $logs ("npm-step1-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
Write-Output "[step1] npm install (logging to $npmLog)..."
cmd.exe /c "npm install > `"$npmLog`" 2>>&1"

$expoLog = Join-Path $logs ("expo-step1-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
$cmd = "/c npx expo start --clear --tunnel > `"$expoLog`" 2>>&1"
Write-Output "[step1] Starting Expo (logging to $expoLog)..."
Start-Process -FilePath "cmd.exe" -ArgumentList $cmd -NoNewWindow
Write-Output "[step1] Done."
