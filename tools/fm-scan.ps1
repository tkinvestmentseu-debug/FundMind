param(
  [string]$RepoPath = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
Set-Location $RepoPath

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

$excludeSegments = @(
  '\.git\', '\.expo\', '\.gradle\', '\.archive\', '\.scannerwork\',
  '\node_modules\', '\android\build\', '\ios\build\', '\dist\', '\build\', '\web-build\', '\.next\', '\coverage\'
)

function Is-Excluded([string]$fullPath) {
  $p = $fullPath.ToLower()
  foreach($seg in $excludeSegments){ if($p -like "*$seg*"){ return $true } }
  return $false
}

$outDir = "tools\scan"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$reportPath = Join-Path $outDir "report.txt"
$keyPath    = Join-Path $outDir "key-findings.txt"

Write-Step "Buduję listę plików (filtrowanie duplikatów i ciężkich katalogów)"
$allDirs  = Get-ChildItem -Recurse -Force -Directory | Where-Object { -not (Is-Excluded $_.FullName) }
$allFiles = Get-ChildItem -Recurse -Force -File      | Where-Object { -not (Is-Excluded $_.FullName) }

$root = (Get-Location).Path
function Rel([string]$p){ return $p.Substring($root.Length).TrimStart('\') }

Write-Step "Generuję drzewo"
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("FUNDmind – SCAN REPORT")
$lines.Add("Root: $root")
$lines.Add("Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$lines.Add("")

$dirsRel  = $allDirs  | ForEach-Object { Rel $_.FullName } | Sort-Object
$filesRel = $allFiles | ForEach-Object { Rel $_.FullName } | Sort-Object

$lines.Add("== Directories ==")
foreach($d in $dirsRel){
  $depth = ($d -split '[\\/]').Count
  $indent = '  ' * ($depth - 1)
  $leaf = ($d -split '[\\/]')[-1]
  $lines.Add("$indent- $leaf")
}
$lines.Add("")
$lines.Add("== Files ==")
foreach($f in $filesRel){
  $depth = ($f -split '[\\/]').Count
  $indent = '  ' * ($depth - 1)
  $leaf = ($f -split '[\\/]')[-1]
  $lines.Add("$indent- $leaf  ($f)")
}

Write-Step "Szukam ekranów Ustawień i nawigacji"
$codeFiles = $allFiles | Where-Object { $_.Name -match '\.(ts|tsx|js|jsx)$' }
$findSettings = $codeFiles | Where-Object { $_.FullName -match 'app[\\/].*settings' }
$findLayout   = $codeFiles | Where-Object { $_.FullName -match 'app[\\/]_layout\.tsx$' }

Write-Step "Szukam elementów motywu (ThemeProvider/useColorScheme itd.)"
$patterns = @(
  'ThemeProvider','useColorScheme','@react-navigation/native',
  'AppThemeProvider','ThemeContext','DarkTheme','DefaultTheme',
  'Appearance','expo-system-ui'
)
$hits = @{}
foreach($pat in $patterns){
  $res = $codeFiles | Select-String -Pattern $pat -SimpleMatch -List -ErrorAction SilentlyContinue
  if($res){
    $paths = $res | Select-Object -ExpandProperty Path -Unique | ForEach-Object { Rel $_ }
    $hits[$pat] = $paths
  }
}

$key = New-Object System.Collections.Generic.List[string]
$key.Add("FUNDmind – KEY FINDINGS")
$key.Add("Root: $root")
$key.Add("")
$key.Add("Settings routes (app/*settings*):")
if($findSettings){ $findSettings | ForEach-Object { $key.Add(" - " + (Rel $_.FullName)) } } else { $key.Add(" - (none)") }

$key.Add("")
$key.Add("_layout files:")
if($findLayout){ $findLayout | ForEach-Object { $key.Add(" - " + (Rel $_.FullName)) } } else { $key.Add(" - (none)") }

$key.Add("")
$key.Add("Theme-related hits:")
if($hits.Keys.Count -eq 0){
  $key.Add(" - (no hits)")
}else{
  foreach($k in $hits.Keys){
    $key.Add(" • $k")
    foreach($p in $hits[$k]){ $key.Add("    - $p") }
  }
}

$lines | Set-Content -Path $reportPath -Encoding UTF8
$key   | Set-Content -Path $keyPath    -Encoding UTF8

Write-Host "`nRaport zapisany:" -ForegroundColor Green
Write-Host " - $reportPath"
Write-Host " - $keyPath"

# VS Code task (bezpieczne dodanie)
$vscodeDir = ".vscode"
$tasksPath = Join-Path $vscodeDir "tasks.json"
if (-not (Test-Path $vscodeDir)) { New-Item -ItemType Directory -Force -Path $vscodeDir | Out-Null }

$tasks = $null
if (Test-Path $tasksPath) { try { $tasks = Get-Content $tasksPath -Raw | ConvertFrom-Json } catch {} }
if (-not $tasks) { $tasks = [pscustomobject]@{ version = "2.0.0"; tasks = @() } }
if (-not ($tasks.PSObject.Properties.Name -contains 'tasks')) {
  $tasks | Add-Member -Force -NotePropertyName tasks -NotePropertyValue @()
} elseif ($null -eq $tasks.tasks) {
  $tasks.tasks = @()
}

$label = "FundMind: Scan project"
if (-not ($tasks.tasks | Where-Object { $_.label -eq $label })) {
  $newTask = [pscustomobject]@{
    label = $label
    type = "shell"
    command = "pwsh"
    args = @("-NoProfile","-ExecutionPolicy","Bypass","-File","tools/fm-scan.ps1")
    problemMatcher = @()
    group = "none"
  }
  $tasks.tasks += $newTask
  $tasks | ConvertTo-Json -Depth 100 | Set-Content $tasksPath -Encoding UTF8
  Write-Host "Dodałem VS Code task: $label" -ForegroundColor DarkGray
}

# Otwórz raport
$codeCmd = Get-Command code -ErrorAction SilentlyContinue
if ($codeCmd) {
  & code $reportPath
  & code $keyPath
} else {
  Start-Process notepad.exe $keyPath
}
