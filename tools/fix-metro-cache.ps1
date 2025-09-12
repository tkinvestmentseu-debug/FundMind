param()

function Ensure-Prop($obj, $name) {
  if (-not ($obj.PSObject.Properties.Name -contains $name)) {
    $obj | Add-Member -MemberType NoteProperty -Name $name -Value (@{})
  }
}

Write-Output "[fix-metro-cache] Patching metro + metro-cache..."

$pkgFile = "D:\FundMind\package.json"
$pkg = Get-Content $pkgFile -Raw | ConvertFrom-Json

Ensure-Prop $pkg "dependencies"
Ensure-Prop $pkg "overrides"

$pkg.dependencies.metro = "0.79.1"
$pkg.dependencies."metro-cache" = "0.79.1"
$pkg.dependencies."@expo/metro-config" = "~0.18.9"

$pkg.overrides."metro-cache" = "0.79.1"

$pkg | ConvertTo-Json -Depth 10 | Set-Content -Path $pkgFile -Encoding UTF8
Write-Output "[fix-metro-cache] package.json pinned (with overrides)."

Write-Output "[fix-metro-cache] Removing node_modules and package-lock.json..."
Set-Location D:\FundMind
if (Test-Path "node_modules") { Remove-Item -Recurse -Force "node_modules" }
if (Test-Path "package-lock.json") { Remove-Item -Force "package-lock.json" }

Write-Output "[fix-metro-cache] Running npm install..."
npm install

Write-Output "[fix-metro-cache] Injecting shim to tools/, node_modules/tools/, and D:\tools..."
$shimSrc = "D:\FundMind\tools\metro-sourcemap-shim.js"
$shimTargets = @(
  "D:\FundMind\tools\metro-sourcemap-shim.js",
  "D:\FundMind\node_modules\tools\metro-sourcemap-shim.js",
  "D:\tools\metro-sourcemap-shim.js"
)
foreach ($t in $shimTargets) {
  if ($shimSrc -ne $t) {
    $dir = Split-Path $t -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
    Copy-Item $shimSrc $t -Force
  }
}
Write-Output "[fix-metro-cache] Shim ready."

Write-Output "[fix-metro-cache] Writing babel.config.js..."
$babelContent = "module.exports = function(api) { api.cache(true); return { presets: ['babel-preset-expo'], plugins: ['expo-router/babel'], }; };"
$babelContent | Set-Content -Path D:\FundMind\babel.config.js -Encoding UTF8

$logDir = "D:\FundMind\logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$logFile = Join-Path $logDir ("expo-fix-metro-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

Write-Output "[fix-metro-cache] Starting Expo..."
& npx expo start --clear --tunnel *>&1 | Tee-Object -FilePath $logFile

Write-Output "--- Last 20 lines of log ---"
Get-Content $logFile -Tail 20
