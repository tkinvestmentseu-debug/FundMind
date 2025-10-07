param(
  [switch]$StartMetro,
  [switch]$RestoreLatest
)

$ErrorActionPreference = "Stop"

function Log($m){ $ts = Get-Date -Format "HH:mm:ss"; Add-Content -Path $logFile -Value ("["+$ts+"] "+$m) }

$projectRoot = "D:\FundMind"
$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }
$logFile = Join-Path $logDir ("remove-budget-widget-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

# Locate Start screen file containing the widget title
# Use unicode-escaped phrase to keep script ASCII-only
$phrase     = [regex]::Unescape("Bud\u017Cet miesi\u0105ca")
$phraseAlt  = "Bud(?:\u017C|z)et\s+miesi(?:\u0105|a)ca"

$startFile = $null
Get-ChildItem -Path (Join-Path $projectRoot "app") -Recurse -Include *.tsx | ForEach-Object {
  $t = Get-Content $_.FullName -Raw
  if ($t -match $phraseAlt) { $startFile = $_.FullName }
}
if (-not $startFile) { Log "ERROR: Start screen not found."; exit 1 }
Log ("Target file: " + $startFile)

# Restore mode (bring back the most recent .bak)
if ($RestoreLatest.IsPresent) {
  $cands = Get-ChildItem ($startFile + ".bak.*") -ErrorAction SilentlyContinue | Sort-Object -Property LastWriteTime -Descending
  if (-not $cands) { Log "No backups to restore."; exit 2 }
  Copy-Item $cands[0].FullName $startFile -Force
  Log ("Restored from: " + $cands[0].FullName)
  if ($StartMetro.IsPresent) {
    try {
      # free port 8081
      $conns = Get-NetTCPConnection -LocalPort 8081 -ErrorAction SilentlyContinue
      if ($conns) { $pids = $conns | Select-Object -ExpandProperty OwningProcess -Unique; foreach($pid in $pids){ Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue } }
      Set-Location $projectRoot
      Start-Process -FilePath "npx" -ArgumentList "expo start --clear --lan" -NoNewWindow
    } catch {}
  }
  exit 0
}

# Backup
$backupPath = $startFile + ".bak." + (Get-Date -Format "yyyyMMdd-HHmmss")
Copy-Item $startFile $backupPath -Force
Log ("Backup: " + $backupPath)

# Load
$text = Get-Content $startFile -Raw

# Remove previous hide markers if any
$hideStart = "{/* HIDE_BUDGET_WIDGET_START */}{false && ("
$hideEnd   = ")}{/* HIDE_BUDGET_WIDGET_END */}"
if ($text -match [regex]::Escape($hideStart)) {
  $text = $text -replace [regex]::Escape($hideStart), ""
  $text = $text -replace [regex]::Escape($hideEnd), ""
  Log "Removed legacy hide markers."
}

$lines = $text -split "`r?`n"

# Find line with the title phrase
$idxPhrase = -1
for ($i=0; $i -lt $lines.Length; $i++) {
  if ($lines[$i] -match $phraseAlt) { $idxPhrase = $i; break }
}
if ($idxPhrase -lt 0) { Log "ERROR: Title line not found."; exit 3 }

# Candidate containers that may wrap the widget
$openRegex = "^\s*<(?<tag>Card|FMCard|LinearGradient|View|Pressable|TouchableOpacity)\b"

function Find-ClosingIdx([string[]]$arr, [int]$openIdx, [string]$tag){
  $depth = 0
  for ($j=$openIdx; $j -lt $arr.Length; $j++){
    if ($arr[$j] -match ("<" + [regex]::Escape($tag) + "\b")) { $depth++ }
    if ($arr[$j] -match ("</" + [regex]::Escape($tag) + ">\s*$")) { $depth-- }
    if ($depth -eq 0 -and $j -gt $openIdx) { return $j }
  }
  return -1
}

# Walk upwards to find the smallest container enclosing the title
$openIdx = -1; $openTag = $null; $closeIdx = -1
for ($i=$idxPhrase; $i -ge 0; $i--){
  $m = [regex]::Match($lines[$i], $openRegex)
  if ($m.Success){
    $tag = $m.Groups["tag"].Value
    $ci = Find-ClosingIdx -arr $lines -openIdx $i -tag $tag
    if ($ci -gt $idxPhrase){
      $openIdx = $i; $openTag = $tag; $closeIdx = $ci
      break
    }
  }
}
if ($openIdx -lt 0 -or $closeIdx -lt 0) { Log "ERROR: Container not found."; exit 4 }
Log ("Removing container <"+$openTag+"> lines "+$openIdx+"-"+$closeIdx)

# Remove block
$beforeCount = $lines.Length
$kept = @()
for ($k=0; $k -lt $lines.Length; $k++){
  if ($k -ge $openIdx -and $k -le $closeIdx) { continue }
  $kept += $lines[$k]
}
# Collapse multiple blank lines
$out = [string]::Join("`r`n", ($kept -join "`n") -split "(`r?`n){2,}" -join "`r`n`r`n")

# Verify: phrase must be gone
if ($out -match $phraseAlt) {
  Log "ERROR: Phrase still present after removal. Restoring backup."
  Copy-Item $backupPath $startFile -Force
  exit 5
}

Set-Content -Path $startFile -Value $out -Encoding UTF8
Log "Saved. Widget removed."

# Optional: restart Metro (force 8081)
if ($StartMetro.IsPresent) {
  try {
    $conns = Get-NetTCPConnection -LocalPort 8081 -ErrorAction SilentlyContinue
    if ($conns) { $pids = $conns | Select-Object -ExpandProperty OwningProcess -Unique; foreach($pid in $pids){ Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue } }
    Set-Location $projectRoot
    Start-Process -FilePath "npx" -ArgumentList "expo start --clear --lan" -NoNewWindow
    Log "Metro restarted."
  } catch { Log ("Metro restart failed: " + $_.Exception.Message) }
}

Log "DONE"
