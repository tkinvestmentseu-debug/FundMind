$ErrorActionPreference = "Stop"

function Ensure-ObjProp { param([object]$obj,[string]$name) if (-not ($obj.PSObject.Properties.Name -contains $name)) { $obj | Add-Member -MemberType NoteProperty -Name $name -Value (@{}) } }
function Set-JsonProp { param([object]$obj,[string]$name,[object]$value) if ($obj.PSObject.Properties.Name -contains $name) { $obj | Add-Member -MemberType NoteProperty -Name $name -Value $value -Force } else { $obj | Add-Member -MemberType NoteProperty -Name $name -Value $value } }

$projectRoot = "D:\FundMind"
$pkgPath = Join-Path $projectRoot "package.json"
$pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json

# Ensure sections
Ensure-ObjProp $pkg "dependencies"
Ensure-ObjProp $pkg "devDependencies"
Ensure-ObjProp $pkg "overrides"

# Remove metro-cache/metro from dependencies and devDependencies
$pkg.dependencies.PSObject.Properties.Remove("metro-cache")
$pkg.dependencies.PSObject.Properties.Remove("metro")
$pkg.devDependencies.PSObject.Properties.Remove("metro-cache")
$pkg.devDependencies.PSObject.Properties.Remove("metro")

# Force overrides
Set-JsonProp $pkg.overrides "metro-cache" "0.79.1"
Set-JsonProp $pkg.overrides "metro" "0.79.1"

# Ensure expo-router pinned
Set-JsonProp $pkg.dependencies "expo-router" "~3.4.7"

# Save back without BOM
$pkg | ConvertTo-Json -Depth 40 | Set-Content -Path $pkgPath -Encoding UTF8
Write-Output "[fix] package.json cleaned and pinned."

# Clean install
$nodeModules = Join-Path $projectRoot "node_modules"
$lockFile = Join-Path $projectRoot "package-lock.json"
if (Test-Path $nodeModules) { Write-Output "[fix] removing node_modules..."; Remove-Item -Recurse -Force $nodeModules }
if (Test-Path $lockFile) { Write-Output "[fix] removing package-lock.json..."; Remove-Item -Force $lockFile }

Write-Output "[fix] npm install..."
cmd.exe /c "npm install > nul 2>&1"

# Ensure expo-router exists
if (-not (Test-Path (Join-Path $projectRoot "node_modules\expo-router\package.json"))) {
  Write-Output "[fix] expo-router missing, installing..."
  cmd.exe /c "npm install expo-router@~3.4.7 >> nul 2>&1"
}

# Start Expo with log
$logsDir = Join-Path $projectRoot "logs"
$expoLog = Join-Path $logsDir ("expo-fix-router-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")
$cmd = "/c npx expo start --clear --tunnel > `"$expoLog`" 2>>&1"
Write-Output "[fix] starting Expo (logging to $expoLog)..."
Start-Process -FilePath "cmd.exe" -ArgumentList $cmd -NoNewWindow

Start-Sleep -Seconds 25
Write-Output ""
Write-Output "--- Last 20 lines of log ---"
Get-Content -Path $expoLog -Tail 20
