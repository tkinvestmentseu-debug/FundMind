# tool: scan-and-shrink-ai-banner.ps1 (PS7, ASCII only)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function New-LogFile([string]$dir){
  $ts = Get-Date -Format yyyyMMdd-HHmmss
  Join-Path $dir ("ai-banner-scan-" + $ts + ".log")
}
function Log([string]$lvl,[string]$msg){
  $line = "[" + (Get-Date -Format s) + "] [" + $lvl + "] " + $msg
  Add-Content -Path $global:LOG -Value $line
  Write-Host $line
}
function Ensure-Backup([string]$file){
  $b = $file + ".bak." + (Get-Date -Format yyyyMMddHHmmss)
  Copy-Item $file $b -Force
  Log "INFO" ("Backup: " + $b)
}

# map for class tokens (~50% smaller)
$MAP = @{
  'text-xl'='text-lg'; 'text-lg'='text-sm'; 'text-base'='text-sm'; 'text-sm'='text-xs';
  'p-6'='p-3'; 'p-5'='p-2'; 'p-4'='p-2'; 'p-3'='p-1'; 'p-2'='p-1';
  'py-6'='py-3'; 'py-5'='py-2'; 'py-4'='py-2'; 'py-3'='py-1'; 'py-2'='py-1';
  'px-6'='px-3'; 'px-5'='px-2'; 'px-4'='px-2'; 'px-3'='px-1'; 'px-2'='px-1'
}

function Shrink-ClassName-In-Line([string]$line){
  $key = "className="
  $i = $line.IndexOf($key)
  if ($i -lt 0) { return @($line,0) }
  $p = $i + $key.Length
  while ($p -lt $line.Length -and [char]::IsWhiteSpace($line[$p])) { $p++ }
  if ($p -ge $line.Length) { return @($line,0) }
  $q = $line[$p]
  if (($q -ne '"') -and ($q -ne "'")) { return @($line,0) }
  $p++
  $end = $line.IndexOf($q, $p)
  if ($end -lt 0) { return @($line,0) }
  $val = $line.Substring($p, $end - $p)
  $parts = @(); $changed = 0
  foreach ($frag in ($val -split ' ')) {
    if ($frag -eq "") { continue }
    if ($MAP.ContainsKey($frag)) { $parts += $MAP[$frag]; $changed++ } else { $parts += $frag }
  }
  if ($changed -le 0) { return @($line,0) }
  $newVal = [string]::Join(" ", $parts)
  $newLine = $line.Substring(0,$p) + $newVal + $line.Substring($end)
  @($newLine, $changed)
}

$LOG = New-LogFile (Join-Path $ENV:ROOT "logs")
# if ENV:ROOT not set (when called standalone), fallback to current script assumptions:
if (-not $LOG) { $LOG = New-LogFile (Join-Path "D:\FundMind" "logs") }

# Scan files
$roots = @()
if (Test-Path "D:\FundMind\app") { $roots += "D:\FundMind\app" }
if (Test-Path "D:\FundMind\src") { $roots += "D:\FundMind\src" }
if ($roots.Count -eq 0) { throw "No app/src roots found" }

$files = @()
foreach ($r in $roots) {
  $files += Get-ChildItem -Path $r -Recurse -File -Include *.tsx -ErrorAction SilentlyContinue
}

Log "INFO" ("Files to scan: " + $files.Count)
$patterns = @("FundMind AI","AI (Premium)","FundMind","AIBanner")
$hitsAll = @()

foreach ($f in $files) {
  [string[]]$lines = Get-Content $f.FullName
  for ($i=0; $i -lt $lines.Count; $i++){
    foreach ($p in $patterns){
      if ($lines[$i].IndexOf($p, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
        $hitsAll += [PSCustomObject]@{ File=$f.FullName; Line=$i }
        break
      }
    }
  }
}
if ($hitsAll.Count -eq 0) {
  Log "ERROR" "No occurrences of FundMind/AIBanner found in app/src. Nothing changed."
  exit 1
}

# Group by file and process
$changedFiles = 0
$changedTokens = 0

$grouped = $hitsAll | Group-Object File
foreach ($g in $grouped) {
  $file = $g.Name
  [string[]]$lines = Get-Content $file
  Ensure-Backup $file
  $lineIdxs = ($g.Group | ForEach-Object { $_.Line }) | Sort-Object -Unique

  Log "INFO" ("Processing file: " + $file + " (hits: " + $lineIdxs.Count + ")")

  $toksFile = 0
  foreach ($hit in $lineIdxs) {
    $from = [Math]::Max(0, $hit - 10)
    $to   = [Math]::Min($lines.Count-1, $hit + 10)

    Log "INFO" ("Hit at line " + $hit + " -> window " + $from + ".." + $to)

    # preview
    $pvFrom = $from
    $pvTo = [Math]::Min($to, $from + 8)
    $preview = ($lines[$pvFrom..$pvTo] -join "`n")
    Log "INFO" "Preview:"
    Log "INFO" $preview

    for ($k=$from; $k -le $to; $k++){
      $res = Shrink-ClassName-In-Line $lines[$k]
      if ($res[1] -gt 0) {
        Log "INFO" ("Change at line " + $k)
        Log "INFO" ("  BEFORE: " + $lines[$k].Trim())
        Log "INFO" ("  AFTER : " + $res[0].Trim())
        $lines[$k] = $res[0]
        $toksFile += [int]$res[1]
      }
    }
  }

  if ($toksFile -gt 0) {
    Set-Content -Path $file -Value $lines -Encoding UTF8
    Log "INFO" ("Written changes in file. Tokens changed: " + $toksFile)
    $changedFiles++
    $changedTokens += $toksFile
  } else {
    Log "WARN" "No className tokens to shrink in this file (maybe inline styles only)."
  }
}

Log "INFO" ("Summary: files changed=" + $changedFiles + ", tokens changed=" + $changedTokens)
if ($changedFiles -eq 0) {
  Log "WARN" "No visual class tokens were changed. Provide the preview from this log and we will target exact JSX."
}
