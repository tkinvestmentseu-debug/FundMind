param()
$ErrorActionPreference = "Stop"
function Fail($m){ Write-Error $m; exit 1 }
$projectRoot = "D:\FundMind"
$layoutPath = Join-Path $projectRoot "app\_layout.tsx"
if (-not (Test-Path -LiteralPath $layoutPath)) { Fail "Missing app\_layout.tsx at $layoutPath" }
$dir = Split-Path -Parent $layoutPath
$latestBak = Get-ChildItem -LiteralPath $dir -Filter "_layout.tsx.bak.*" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $latestBak) { Fail "No backup files found for _layout.tsx" }
$ts = (Get-Date).ToString("yyyyMMdd_HHmmss")
$replaced = $layoutPath + ".replaced." + $ts
Copy-Item -LiteralPath $layoutPath -Destination $replaced -Force
Copy-Item -LiteralPath $latestBak.FullName -Destination $layoutPath -Force
Write-Host "Restored from backup: $($latestBak.FullName)"
