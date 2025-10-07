param(
  [switch]$StartMetro
)

$ErrorActionPreference = "Stop"

function Log($msg) {
  $ts = Get-Date -Format "HH:mm:ss"
  Add-Content -Path $logFile -Value ("[" + $ts + "] " + $msg)
}

$projectRoot = "D:\FundMind"
$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }
$logFile = Join-Path $logDir ("calendar-patch-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

$calendarFile = Join-Path $projectRoot "app\calendar.tsx"
if (-not (Test-Path $calendarFile)) {
  Log "calendar.tsx not found at app\calendar.tsx"
  exit 1
}

# Backup first
$backupPath = $calendarFile + ".bak." + (Get-Date -Format "yyyyMMdd-HHmmss")
Copy-Item $calendarFile $backupPath -Force
Log ("Backup created: " + $backupPath)

# Read file
$content = Get-Content $calendarFile -Raw

# Build unicode strings from ASCII-only escapes
$phraseEsc  = "Brak nadchodz\u0105cych wydarz\u017Ce\u0144"
$headerEsc  = "Nadchodz\u0105ce wydarzenia"
$bulletEsc  = "\u2022"  # bullet dot

$phrase = [regex]::Unescape($phraseEsc)
$header = [regex]::Unescape($headerEsc)
$bullet = [regex]::Unescape($bulletEsc)

# If already patched (row layout with phrase present), do nothing
if ( ($content -match "flexDirection:\s*'row'") -and ($content -match [regex]::Escape($phrase)) ) {
  Log "Already patched. No changes needed."
  exit 0
}

# Prefer replacing a <Text>...</Text> node containing the phrase
$nodePattern = "<Text[^>]*>\s*" + [regex]::Escape($phrase) + "\s*</Text>"

# Replacement block (uses no external icon deps)
$replacement = "<View style={{flexDirection: 'row', alignItems: 'center', marginTop: 8}}><Text style={{fontSize: 14}}>" + $bullet + "</Text><Text style={{color: '#6B7280', marginLeft: 6}}>" + $phrase + "</Text></View>"

$patched = $false
if ([regex]::IsMatch($content, $nodePattern)) {
  $content = [regex]::Replace($content, $nodePattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $replacement }, 1)
  Log "Applied direct Text-node replacement."
  $patched = $true
} else {
  # Fallback: insert block after the header and remove line with phrase if present
  $lines = $content -split "`r?`n"

  $idxHeader = -1
  for ($i=0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match [regex]::Escape($header)) { $idxHeader = $i; break }
  }

  $idxPhrase = -1
  for ($i=0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match [regex]::Escape($phrase)) { $idxPhrase = $i; break }
  }

  if ($idxHeader -ge 0) {
    # Remove the phrase line if it exists
    if ($idxPhrase -ge 0) {
      $lines = $lines[0..($idxPhrase-1)] + $lines[($idxPhrase+1)..($lines.Length-1)]
    }
    # Insert after header
    $insertAt = [Math]::Min($idxHeader + 1, $lines.Length)
    $newLines = @()
    for ($j=0; $j -lt $lines.Length; $j++) {
      $newLines += $lines[$j]
      if ($j -eq $insertAt) { $newLines += "  " + $replacement }
    }
    $content = [string]::Join("`r`n", $newLines)
    Log "Applied header-insert fallback."
    $patched = $true
  } elseif ($idxPhrase -ge 0) {
    # Last-resort: pure substring replace
    $content = $content -replace [regex]::Escape($phrase), $replacement
    Log "Applied pure substring fallback."
    $patched = $true
  }
}

if (-not $patched) {
  Log "No safe edit point found. Restoring backup."
  Copy-Item $backupPath $calendarFile -Force
  exit 2
}

# Save
Set-Content -Path $calendarFile -Value $content -Encoding UTF8
Log "File saved."

# Verify patch integrity
$verify = Get-Content $calendarFile -Raw
$ok = ($verify -match "flexDirection:\s*'row'") -and ($verify -match [regex]::Escape($phrase)) -and (-not [regex]::IsMatch($verify, $nodePattern))
if ($ok) {
  Log "Verification OK."
} else {
  Log "Verification FAILED. Restoring backup."
  Copy-Item $backupPath $calendarFile -Force
  exit 3
}

# Optional: restart Metro with clear cache
if ($StartMetro.IsPresent) {
  try {
    Set-Location $projectRoot
    Log "Starting Metro: expo start --clear"
    Start-Process -FilePath "npx" -ArgumentList "expo start --clear" -NoNewWindow
  } catch {
    Log ("Metro start failed: " + $_.Exception.Message)
    exit 4
  }
}

Log "Done."
