param(
  [string]$projectRoot = "D:\FundMind",
  [switch]$fixRouter = $true,
  [switch]$runChecks = $true,
  [switch]$startDev = $false,
  [string]$devIP = "192.168.0.16",
  [int]$devPort = 8081,
  [switch]$clearMetro = $false,
  [string]$logFile = ""
)
$ErrorActionPreference = "Stop"
function Fail($m){ if($logFile){ Add-Content -LiteralPath $logFile -Value $m }; Write-Error $m; exit 1 }
function Info($m){ if($logFile){ Add-Content -LiteralPath $logFile -Value $m }; Write-Host $m }
if (-not (Test-Path -LiteralPath $projectRoot)) { Fail "Project root not found: $projectRoot" }
$ts = (Get-Date).ToString("yyyyMMdd_HHmmss")
$logsDir = Join-Path $projectRoot "logs"
if (-not (Test-Path -LiteralPath $logsDir)) { New-Item -ItemType Directory -Force -Path $logsDir | Out-Null }
if (-not $logFile -or $logFile -eq "") { $logFile = Join-Path $logsDir ("fundmind_router_audit_run_" + $ts + ".log") }
$toolsDir = Join-Path $projectRoot "tools"
$appDir = Join-Path $projectRoot "app"

Info "=== FundMind Router Audit $ts ==="
Info "projectRoot: $projectRoot"

if (-not (Test-Path -LiteralPath $appDir)) { Fail "Missing app/ directory at $appDir" }

# 1) Move misplaced configs from app/ to root (babel, metro, tsconfig)
$misplaced = @("babel.config.js","metro.config.js","tsconfig.json")
foreach($cfg in $misplaced){
  $src = Join-Path $appDir $cfg
  $dst = Join-Path $projectRoot $cfg
  if (Test-Path -LiteralPath $src) {
    $bak = $dst + ".bak." + $ts
    if (Test-Path -LiteralPath $dst) { Copy-Item -LiteralPath $dst -Destination $bak -Force; Info "Backup existing root $cfg -> $bak" }
    Move-Item -LiteralPath $src -Destination $dst -Force
    Info "Moved $cfg from app/ to root"
  }
}

# 2) Router duplicate detection & fix
# Rules:
# - Special names to ignore: "_layout", files starting with "+", dynamic segments [], and group segments () remain as-is
# - Prefer folder + index.tsx; if a file app\<name>.tsx exists and no folder, create folder and move file to folder\index.tsx
# - If both file and folder\index.tsx exist, keep folder\index.tsx and back up the file <name>.tsx as .replaced.<ts>
$entries = Get-ChildItem -LiteralPath $appDir -File -Filter "*.tsx"
foreach($file in $entries){
  $name = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
  if ($name -eq "_layout") { continue }
  if ($name.StartsWith("+")) { continue }
  if ($name.Contains("[") -or $name.Contains("]")) { continue }
  if ($name.StartsWith("(") -and $name.EndsWith(")")) { continue }
  $folder = Join-Path $appDir $name
  $folderIndex = Join-Path $folder "index.tsx"
  if (Test-Path -LiteralPath $folderIndex) {
    # both exist -> back up the flat file
    $repl = Join-Path $appDir ($name + ".tsx.replaced." + $ts)
    Copy-Item -LiteralPath $file.FullName -Destination $repl -Force
    Remove-Item -LiteralPath $file.FullName -Force
    Info "Duplicate route: kept $($folderIndex.Replace($projectRoot,'')), replaced flat file -> $repl"
  } else {
    if ($fixRouter) {
      if (-not (Test-Path -LiteralPath $folder)) { New-Item -ItemType Directory -Force -Path $folder | Out-Null }
      $dest = $folderIndex
      $bak = $file.FullName + ".bak." + $ts
      Copy-Item -LiteralPath $file.FullName -Destination $bak -Force
      Move-Item -LiteralPath $file.FullName -Destination $dest -Force
      Info "Promoted route to folder+index: $($dest.Replace($projectRoot,'')) (backup: $bak)"
    } else {
      Info "Detected flat route $($file.FullName.Replace($projectRoot,'')) (no action)"
    }
  }
}

# 3) Safety check: ensure no NavigationContainer usage in project (expo-router only)
$navMatches = Select-String -Path (Join-Path $projectRoot "*") -Pattern "NavigationContainer" -SimpleMatch -ErrorAction SilentlyContinue
foreach($m in $navMatches){
  Info "Warning: Found NavigationContainer reference at $($m.Path)"
}

# 4) Run checks
if ($runChecks) {
  Set-Location -LiteralPath $projectRoot
  Info "Running: npm run lint"
  npm run lint 2>&1 | Tee-Object -FilePath $logFile
  Info "Running: npm run typecheck"
  npm run typecheck 2>&1 | Tee-Object -FilePath $logFile -Append
  Info "Running: npm run test"
  npm run test 2>&1 | Tee-Object -FilePath $logFile -Append

  # Optional coverage
  Info "Running: npm run coverage"
  npm run coverage 2>&1 | Tee-Object -FilePath $logFile -Append

  # Aggregate result: if last command failed, exit non-zero
  if ($LASTEXITCODE -ne 0) {
    Fail "Checks failed. See log: $logFile"
  } else {
    Info "Checks OK."
  }
}

# 5) Commit if git and checks OK
$gitDir = Join-Path $projectRoot ".git"
if (Test-Path -LiteralPath $gitDir) {
  try {
    Set-Location -LiteralPath $projectRoot
    git add -A
    git commit -m "chore(router): audit fix, config move, tools" | Out-Null
    Info "Committed changes."
  } catch {
    Info "Git commit skipped or failed: $($_.Exception.Message)"
  }
}

# 6) Optionally start dev server
if ($startDev) {
  $cmd = Join-Path $toolsDir "dev-start.ps1"
  & $cmd -projectRoot $projectRoot -devIP $devIP -devPort $devPort -clearMetro:$clearMetro
}

Info "Done. Log: $logFile"