param(
  [string]$ProjectRoot = "D:\\FundMind",
  [double]$Scale = 1.5,
  [int]$Offset = -16
)

$ErrorActionPreference = "Stop"

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$logsDir = Join-Path $ProjectRoot "logs"
if (-not (Test-Path $logsDir)) { New-Item -Path $logsDir -ItemType Directory | Out-Null }
$logFile = Join-Path $logsDir ("logo-boost-all-v2-" + $ts + ".log")

function Log([string]$msg) {
  $line = ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $msg)
  $line | Tee-Object -FilePath $logFile -Append
}

Log "Start logo search & boost v2. Root: $ProjectRoot, scale=$Scale, marginTop=$Offset"

$appDir = Join-Path $ProjectRoot "app"
if (-not (Test-Path $appDir)) { Log "ERROR: app dir missing: $appDir"; throw "app dir missing" }

# --- Search phase ---
$patterns = @("HeaderLogo","logo\.png","logo\.jpg","logo\.jpeg","logo\.webp","logo\.svg")
$codeFiles = Get-ChildItem -Path $appDir -Recurse -File -Include *.tsx,*.ts
$hits = @()

foreach ($f in $codeFiles) {
  foreach ($pat in $patterns) {
    if (Select-String -Path $f.FullName -Pattern $pat -SimpleMatch:$false -Quiet) {
      $hits += $f.FullName; break
    }
  }
}
$hits = $hits | Sort-Object -Unique

if ($hits.Count -eq 0) {
  Log "No files with logo patterns found."
} else {
  Log "Found files potentially using the logo:"
  $hits | ForEach-Object { Log (" - " + $_) }
}

# Pokaż konkretne linie z HeaderLogo
Log "Snippets for 'HeaderLogo':"
foreach ($f in $hits) {
  $ms = Select-String -Path $f -Pattern "HeaderLogo" -Context 0,1 -ErrorAction SilentlyContinue
  if ($ms) {
    Log ("--- " + $f)
    foreach ($m in $ms) { Log ("  [" + $m.LineNumber + "] " + $m.Line.Trim()) }
  }
}

# --- Patch phase ---
$markerV1Start = "{/* FUNDLOGO_WRAP_v1 START */}"
$markerV1End   = "{/* FUNDLOGO_WRAP_v1 END */}"
$markerV2Start = "{/* FUNDLOGO_WRAP_v2 START */}"
$markerV2End   = "{/* FUNDLOGO_WRAP_v2 END */}"

# Nowy wrapper v2 (scale/offset parametryzowane)
$newWrap = $markerV2Start + "`n" +
"<View style={{ transform:[{ scale:" + $Scale + " }], marginTop:" + $Offset + ", alignSelf:'center' }}>" + "`n" +
"  <HeaderLogo />" + "`n" +
"</View>" + "`n" +
$markerV2End + "`n"

# Regexy
$rxSelfClose = '<HeaderLogo([^>]*)\/>'
$rxSimpleWrap = '<View\s+style=\{\{[\s\S]*?\}\}>\s*<HeaderLogo\s*\/>\s*<\/View>'

# Update dla starych wrapperow v1 -> v2 (zachowujemy tylko zawartosc <HeaderLogo/>)
# Szukamy bloku miedzy markerami v1 i zamieniamy na v2
$rxV1Block = [regex]::Escape($markerV1Start) + '[\s\S]*?' + [regex]::Escape($markerV1End)

# Update dla istniejacego v2 z inna skala/offsetem -> przepisujemy na aktualne parametry
$rxV2Block = [regex]::Escape($markerV2Start) + '[\s\S]*?' + [regex]::Escape($markerV2End)

# Targety: pliki z HeaderLogo
$targets = $hits | Where-Object { Select-String -Path $_ -Pattern "HeaderLogo" -Quiet }

$patchedCount = 0
foreach ($file in $targets) {
  try {
    $orig = Get-Content -Path $file -Raw
    $work = $orig
    $changed = $false

    # 1) Upgrade v1 -> v2
    if ($work -match $rxV1Block) {
      $work = [regex]::Replace($work, $rxV1Block, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $newWrap }, 0)
      $changed = $true
    }

    # 2) Refresh existing v2 to new params (if rerun with different Scale/Offset)
    if ($work -match $rxV2Block) {
      $work = [regex]::Replace($work, $rxV2Block, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $newWrap }, 0)
      $changed = $true
    }

    # 3) Wrap ALL self-closing <HeaderLogo /> occurrences (global, not just first)
    if ($work -match $rxSelfClose) {
      $work = [regex]::Replace($work, $rxSelfClose, $newWrap, 0)
      $changed = $true
    }

    # 4) Replace existing simple wrappers (global)
    if ($work -match $rxSimpleWrap) {
      $work = [regex]::Replace($work, $rxSimpleWrap, $newWrap, 0)
      $changed = $true
    }

    if ($changed) {
      $backup = $file + ".bak." + $ts
      Copy-Item -Path $file -Destination $backup -Force
      Set-Content -Path $file -Value $work -Encoding UTF8
      Log ("Patched: " + $file)
      $patchedCount++
    } else {
      Log ("NO-CHANGE: " + $file + " (no match or already correct)")
    }
  } catch {
    Log ("ERROR patching " + $file + ": " + $_.Exception.Message)
    Write-Host ("ERROR: " + $file + " -> " + $_.Exception.Message)
  }
}

Log ("Patched files total: " + $patchedCount)
Log "Done. Press 'r' in Metro to reload."
Write-Host ("Log: " + $logFile)