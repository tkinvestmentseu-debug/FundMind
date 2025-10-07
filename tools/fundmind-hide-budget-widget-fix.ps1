param(
  [switch]$StartMetro
)

$ErrorActionPreference = "Stop"

function Log($m){ $ts=Get-Date -Format "HH:mm:ss"; Add-Content -Path $logFile -Value ("["+$ts+"] "+$m) }

$projectRoot = "D:\FundMind"
$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }
$logFile = Join-Path $logDir ("hide-budget-widget-fix-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

# Locate Start screen
$phrase = [regex]::Unescape("Bud\u017Cet miesi\u0105ca")
$phraseAlt = "Bud[z\u017C]et\s+miesi[a\u0105]ca"
$startFile = $null
Get-ChildItem -Path (Join-Path $projectRoot "app") -Recurse -Include *.tsx | ForEach-Object {
  $t = Get-Content $_.FullName -Raw
  if ($t -match $phraseAlt) { $startFile = $_.FullName }
}
if (-not $startFile) { Log "ERROR: Start screen not found."; exit 1 }
Log ("Target file: " + $startFile)

# Backup
$backup = $startFile + ".bak." + (Get-Date -Format "yyyyMMdd-HHmmss")
Copy-Item $startFile $backup -Force
Log ("Backup: " + $backup)

# Load and clean previous broken markers
$startMarker = "{/* HIDE_BUDGET_WIDGET_START */}{false && ("
$endMarker   = ")}{/* HIDE_BUDGET_WIDGET_END */}"
$text = Get-Content $startFile -Raw
if ($text -match [regex]::Escape($startMarker)) {
  $text = $text -replace [regex]::Escape($startMarker), ""
  $text = $text -replace [regex]::Escape($endMarker), ""
  Log "Removed previous markers."
}

# Split to lines
$lines = $text -split "`r?`n"

# Find line with the title phrase
$idxPhrase = -1
for ($i=0; $i -lt $lines.Length; $i++) {
  if ($lines[$i] -match $phraseAlt) { $idxPhrase = $i; break }
}
if ($idxPhrase -lt 0) { Log "ERROR: Title line not found."; exit 2 }

# Candidate opening tags
$tagRegex = "^\s*<(?<tag>Card|FMCard|LinearGradient|View|Pressable|TouchableOpacity)\b"

# Function: find matching closing index for a given tag starting at openIdx
function Find-ClosingIdx([string[]]$arr, [int]$openIdx, [string]$tag){
  $depth = 0
  for ($j=$openIdx; $j -lt $arr.Length; $j++){
    if ($arr[$j] -match ("<" + [regex]::Escape($tag) + "\b")) { $depth++ }
    if ($arr[$j] -match ("</" + [regex]::Escape($tag) + ">\s*$")) { $depth-- }
    if ($depth -eq 0 -and $j -gt $openIdx) { return $j }
  }
  return -1
}

# Walk upwards to find the smallest container that actually encloses the phrase
$openIdx = -1; $openTag = $null; $closeIdx = -1
for ($i=$idxPhrase; $i -ge 0; $i--){
  $m = [regex]::Match($lines[$i], $tagRegex)
  if ($m.Success){
    $tag = $m.Groups["tag"].Value
    $ci = Find-ClosingIdx -arr $lines -openIdx $i -tag $tag
    if ($ci -gt $idxPhrase){
      $openIdx = $i; $openTag = $tag; $closeIdx = $ci
      break
    }
  }
}
if ($openIdx -lt 0 -or $closeIdx -lt 0){ Log "ERROR: Container not found."; exit 3 }
Log ("Chosen container: <"+$openTag+"> lines "+$openIdx+"-"+$closeIdx)

# Insert safe wrapper
$startMarker = "{/* HIDE_BUDGET_WIDGET_START */}{false && ("
$endMarker   = ")}{/* HIDE_BUDGET_WIDGET_END */}"
$new = New-Object System.Collections.Generic.List[string]
for ($k=0; $k -lt $lines.Length; $k++){
  if ($k -eq $openIdx) { $new.Add($startMarker) ; $new.Add($lines[$k]) }
  elseif ($k -eq $closeIdx) { $new.Add($lines[$k]) ; $new.Add($endMarker) }
  else { $new.Add($lines[$k]) }
}
$out = [string]::Join("`r`n", $new.ToArray())

# Verify: markers present and phrase still exists within block range
$ok = ($out -match [regex]::Escape($startMarker)) -and ($out -match [regex]::Escape($endMarker))
if (-not $ok){ Log "ERROR: Verification failed."; Copy-Item $backup $startFile -Force; exit 4 }

Set-Content -Path $startFile -Value $out -Encoding UTF8
Log "Saved."

# Optional: restart Metro on a free port 8081
if ($StartMetro.IsPresent){
  try{
    # Kill any node listening on 8081 (Windows)
    $p = Get-NetTCPConnection -LocalPort 8081 -ErrorAction SilentlyContinue
    if ($p) {
      $pid = (Get-Process -Id ($p.OwningProcess) -ErrorAction SilentlyContinue).Id
      if ($pid) { Stop-Process -Id $pid -Force; Log ("Killed process on 8081: PID "+$pid) }
    }
  } catch { Log ("Port check failed: " + $_.Exception.Message) }

  try{
    Set-Location $projectRoot
    Log "Starting Metro: expo start --clear"
    Start-Process -FilePath "npx" -ArgumentList "expo start --clear" -NoNewWindow
  } catch { Log ("Metro start failed: " + $_.Exception.Message) }
}

Log "DONE"
