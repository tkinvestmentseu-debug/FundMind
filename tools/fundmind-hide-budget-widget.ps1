param(
  [switch]$StartMetro,
  [switch]$Unhide
)

$ErrorActionPreference = "Stop"

function Log($msg) {
  $ts = Get-Date -Format "HH:mm:ss"
  Add-Content -Path $logFile -Value ("[" + $ts + "] " + $msg)
}

$projectRoot = "D:\FundMind"
$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }
$logFile = Join-Path $logDir ("hide-budget-widget-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

# Find Start screen file containing the widget text
# Phrase pattern tolerates diacritics: Bud(z|ż)et miesi(a|ą)ca
$phrasePattern = "Bud(?:\u017C|z)et\s+miesi(?:\u0105|a)ca"
$startFile = $null

Get-ChildItem -Path (Join-Path $projectRoot "app") -Recurse -Include *.tsx | ForEach-Object {
  $t = Get-Content $_.FullName -Raw
  if ($t -match $phrasePattern) { $startFile = $_.FullName }
}

if (-not $startFile) {
  Log "ERROR: Could not locate Start screen file with 'Budzet/Bud\u017Cet miesi\u0105ca'."
  exit 1
}

Log ("Target file: " + $startFile)

# Backup
$backupPath = $startFile + ".bak." + (Get-Date -Format "yyyyMMdd-HHmmss")
Copy-Item $startFile $backupPath -Force
Log ("Backup: " + $backupPath)

# Load
$text = Get-Content $startFile -Raw

# Unhide (revert) if requested
$startMarker = "{/* HIDE_BUDGET_WIDGET_START */}{false && ("
$endMarker   = ")}{/* HIDE_BUDGET_WIDGET_END */}"

if ($Unhide.IsPresent) {
  $before = $text
  $text = $text -replace [regex]::Escape($startMarker), ""
  $text = $text -replace [regex]::Escape($endMarker), ""
  if ($text -ne $before) {
    Set-Content -Path $startFile -Value $text -Encoding UTF8
    Log "Unhide done. Markers removed."
  } else {
    Log "No markers found. Nothing to unhide."
  }
  if ($StartMetro.IsPresent) {
    try { Set-Location $projectRoot; Start-Process -FilePath "npx" -ArgumentList "expo start --clear" -NoNewWindow } catch {}
  }
  exit 0
}

# If already hidden, exit
if ($text -match [regex]::Escape($startMarker)) {
  Log "Already hidden. Nothing to do."
  exit 0
}

# Work on lines to place markers around the container that holds the phrase
$lines = $text -split "`r?`n"
$phraseLine = -1
for ($i=0; $i -lt $lines.Length; $i++) {
  if ($lines[$i] -match $phrasePattern) { $phraseLine = $i; break }
}
if ($phraseLine -lt 0) {
  Log "ERROR: Phrase line not found (unexpected)."
  exit 2
}

# Find opening tag line above the phrase
$openIdx = -1
$openTag = $null
$openRegex = "^\s*<(?<tag>Card|View|Pressable|TouchableOpacity|FMCard)\b"
for ($i=$phraseLine; $i -ge 0; $i--) {
  $m = [regex]::Match($lines[$i], $openRegex)
  if ($m.Success) { $openIdx = $i; $openTag = $m.Groups["tag"].Value; break }
}
if ($openIdx -lt 0) {
  Log "ERROR: Opening container not found."
  exit 3
}

# Find closing tag line for the same component
$closeIdx = -1
$closeRegex = "^\s*</" + [regex]::Escape($openTag) + ">\s*$"
for ($i=$phraseLine; $i -lt $lines.Length; $i++) {
  if ($lines[$i] -match $closeRegex) { $closeIdx = $i; break }
}
if ($closeIdx -lt 0 -or $closeIdx -lt $openIdx) {
  Log "ERROR: Closing tag for <$openTag> not found."
  exit 4
}

# Insert markers
$new = New-Object System.Collections.Generic.List[string]
for ($i=0; $i -lt $lines.Length; $i++) {
  if ($i -eq $openIdx) {
    $new.Add($startMarker)
    $new.Add($lines[$i])
  } elseif ($i -eq $closeIdx) {
    $new.Add($lines[$i])
    $new.Add($endMarker)
  } else {
    $new.Add($lines[$i])
  }
}

$out = [string]::Join("`r`n", $new.ToArray())

# Basic verification: markers present and phrase still present (inside hidden block)
if ( ($out -match [regex]::Escape($startMarker)) -and ($out -match [regex]::Escape($endMarker)) -and ($out -match $phrasePattern) ) {
  Set-Content -Path $startFile -Value $out -Encoding UTF8
  Log ("Hidden <$openTag> block lines " + $openIdx + "-" + $closeIdx)
} else {
  Log "ERROR: Verification failed, restoring backup."
  Copy-Item $backupPath $startFile -Force
  exit 5
}

# Optional: restart Metro (clear cache)
if ($StartMetro.IsPresent) {
  try {
    Set-Location $projectRoot
    Log "Starting Metro: expo start --clear"
    Start-Process -FilePath "npx" -ArgumentList "expo start --clear" -NoNewWindow
  } catch {
    Log ("Metro start failed: " + $_.Exception.Message)
  }
}

Log "DONE"
