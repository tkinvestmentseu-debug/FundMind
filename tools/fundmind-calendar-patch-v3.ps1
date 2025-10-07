param([switch]$StartMetro)

$ErrorActionPreference = "Stop"

function Log($msg) {
  $ts = Get-Date -Format "HH:mm:ss"
  Add-Content -Path $logFile -Value ("[" + $ts + "] " + $msg)
}

$projectRoot = "D:\FundMind"
$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }
$logFile = Join-Path $logDir ("calendar-patch-v3-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

$calendarFile = Join-Path $projectRoot "app\calendar.tsx"
if (-not (Test-Path $calendarFile)) {
  Log "ERROR: app\\calendar.tsx not found."
  exit 1
}

# Backup
$backupPath = $calendarFile + ".bak." + (Get-Date -Format "yyyyMMdd-HHmmss")
Copy-Item $calendarFile $backupPath -Force
Log ("Backup: " + $backupPath)

# Read file
$content = Get-Content $calendarFile -Raw

# Target phrases (unicode built at runtime)
$phrase = [regex]::Unescape("Brak nadchodz\u0105cych wydarze\u0144")
$header = [regex]::Unescape("Nadchodz\u0105ce wydarzenia")
$bullet = [regex]::Unescape("\u2022")

# Patterns to catch most variants
$phraseLoose = "Brak\s+nadchod\S+\s+wydarz\S+"                  # tolerancyjny
$nodeTextA   = "<Text[^>]*>\s*" + [regex]::Escape($phrase) + "\s*</Text>"
$nodeTextB   = "<Text[^>]*>\s*\{?\s*['""]" + [regex]::Escape($phrase) + "['""]\s*\}?\s*</Text>"
$nodeTextC   = "<Text[^>]*>.*?" + [regex]::Escape($phrase) + ".*?<\/Text>"

# Replacement block (no external icons)
$replacement = "<View style={{flexDirection: 'row', alignItems: 'center', marginTop: 8}}><Text style={{fontSize: 14}}>" + $bullet + "</Text><Text style={{color: '#6B7280', marginLeft: 6}}>" + $phrase + "</Text></View>"

$patched = $false
$appliedPattern = ""

# 1) Exact simple <Text>phrase</Text>
if ([regex]::IsMatch($content, $nodeTextA)) {
  $content = [regex]::Replace($content, $nodeTextA, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $replacement }, 1)
  $patched = $true; $appliedPattern = "nodeTextA"
  Log "Applied pattern nodeTextA."
} elseif ([regex]::IsMatch($content, $nodeTextB)) {
  $content = [regex]::Replace($content, $nodeTextB, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $replacement }, 1)
  $patched = $true; $appliedPattern = "nodeTextB"
  Log "Applied pattern nodeTextB."
} elseif ([regex]::IsMatch($content, $nodeTextC)) {
  $content = [regex]::Replace($content, $nodeTextC, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $replacement }, 1)
  $patched = $true; $appliedPattern = "nodeTextC"
  Log "Applied pattern nodeTextC."
} else {
  # 2) Fallback: insert right after header line and drop the old loose phrase line if present
  $lines = $content -split "`r?`n"
  $idxHeader = -1
  for ($i=0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match [regex]::Escape($header)) { $idxHeader = $i; break }
  }
  $idxPhrase = -1
  for ($i=0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match $phraseLoose) { $idxPhrase = $i; break }
  }
  if ($idxHeader -ge 0) {
    if ($idxPhrase -ge 0) {
      $lines = $lines[0..($idxPhrase-1)] + $lines[($idxPhrase+1)..($lines.Length-1)]
      Log ("Removed old phrase line at " + $idxPhrase)
    }
    $insertAt = [Math]::Min($idxHeader + 1, $lines.Length)
    $newLines = @()
    for ($j=0; $j -lt $lines.Length; $j++) {
      $newLines += $lines[$j]
      if ($j -eq $insertAt) { $newLines += "  " + $replacement }
    }
    $content = [string]::Join("`r`n", $newLines)
    $patched = $true; $appliedPattern = "header-insert"
    Log "Applied header-insert fallback."
  }
}

if (-not $patched) {
  Log "ERROR: No safe edit point found. Restoring backup."
  Copy-Item $backupPath $calendarFile -Force
  exit 2
}

# Save and verify
Set-Content -Path $calendarFile -Value $content -Encoding UTF8
$verify = Get-Content $calendarFile -Raw
$ok = ($verify -match "flexDirection:\s*'row'") -and ($verify -match [regex]::Escape($phrase)) -and ($verify -notmatch $nodeTextA) -and ($verify -notmatch $nodeTextB)
if ($ok) {
  Log ("Verification OK. Pattern: " + $appliedPattern)
} else {
  Log "ERROR: Verification failed. Restoring backup."
  Copy-Item $backupPath $calendarFile -Force
  exit 3
}

if ($StartMetro.IsPresent) {
  try {
    Set-Location $projectRoot
    Log "Starting Metro: expo start --clear"
    Start-Process -FilePath "npx" -ArgumentList "expo start --clear" -NoNewWindow
  } catch { Log ("Metro start failed: " + $_.Exception.Message); exit 4 }
}

Log "DONE"
