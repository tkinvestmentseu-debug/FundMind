param(
  [string]$ProjectRoot = "D:\\FundMind",
  [double]$Scale = 1.5,
  [int]$Offset = -16
)

$ErrorActionPreference = "Stop"

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$logsDir = Join-Path $ProjectRoot "logs"
if (-not (Test-Path $logsDir)) { New-Item -Path $logsDir -ItemType Directory | Out-Null }
$logFile = Join-Path $logsDir ("fix-logo-wrapper-v2b-" + $ts + ".log")

function Log([string]$msg) {
  $line = ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $msg)
  $line | Tee-Object -FilePath $logFile -Append
}

Log "Start fix-logo-wrapper v2b. Root: $ProjectRoot, scale=$Scale, marginTop=$Offset"

$appDir = Join-Path $ProjectRoot "app"
if (-not (Test-Path $appDir)) { Log "ERROR: app dir missing: $appDir"; throw "app dir missing" }

# --- Search phase ---
$codeFiles = Get-ChildItem -Path $appDir -Recurse -File -Include *.tsx,*.ts
$targets = @()
foreach ($f in $codeFiles) {
  if (Select-String -Path $f.FullName -Pattern "HeaderLogo|FUNDLOGO_WRAP_v1|FUNDLOGO_WRAP_v2" -Quiet) {
    $targets += $f.FullName
  }
}
$targets = $targets | Sort-Object -Unique

if ($targets.Count -eq 0) {
  Log "No files with HeaderLogo or markers found."
  Write-Host ("Log: " + $logFile)
  exit 0
}

Log "Candidates:"
$targets | ForEach-Object { Log (" - " + $_) }

Log "Snippets (HeaderLogo/markers):"
foreach ($f in $targets) {
  $ms = Select-String -Path $f -Pattern "HeaderLogo|FUNDLOGO_WRAP_v1|FUNDLOGO_WRAP_v2" -Context 0,1 -ErrorAction SilentlyContinue
  if ($ms) {
    Log ("--- " + $f)
    foreach ($m in $ms) { Log ("  [" + $m.LineNumber + "] " + $m.Line.Trim()) }
  }
}

# --- Repair phase ---
$markerV1Start = "{/* FUNDLOGO_WRAP_v1 START */}"
$markerV1End   = "{/* FUNDLOGO_WRAP_v1 END */}"
$markerV2Start = "{/* FUNDLOGO_WRAP_v2 START */}"
$markerV2End   = "{/* FUNDLOGO_WRAP_v2 END */}"

$canonical = $markerV2Start + "`n" +
"<View style={{ transform:[{ scale:" + $Scale + " }], marginTop:" + $Offset + ", alignSelf:'center' }}>" + "`n" +
"  <HeaderLogo />" + "`n" +
"</View>" + "`n" +
$markerV2End + "`n"

# Regexy blokow (nie-lakome):
$rxBlockV1 = [regex]('\Q' + $markerV1Start + '\E[\s\S]*?\Q' + $markerV1End + '\E', [System.Text.RegularExpressions.RegexOptions]::Singleline)
$rxBlockV2 = [regex]('\Q' + $markerV2Start + '\E[\s\S]*?\Q' + $markerV2End + '\E', [System.Text.RegularExpressions.RegexOptions]::Singleline)

# Duplikaty END (globalnie)
$endLiteral = $markerV2End
$endPattern = '\Q' + $endLiteral + '\E(?:\s*(?:\r?\n)?\s*\Q' + $endLiteral + '\E)+'

# Surowe tagi HeaderLogo
$rxSelfClose = [regex]'<HeaderLogo([^>]*)\/>'

$patchedTotal = 0

foreach ($file in $targets) {
  $orig = Get-Content -Path $file -Raw
  $work = $orig
  $changed = $false

  # CRLF -> LF (latwiej operowac)
  $work = $work -replace "`r`n","`n"

  # 1) Zastap WSZYSTKIE bloki v1 kanonicznym v2
  if ($rxBlockV1.IsMatch($work)) {
    $work = $rxBlockV1.Replace($work, { param($m) $canonical })
    $changed = $true
  }

  # 2) Zastap WSZYSTKIE bloki v2 kanonicznym v2 (czysci srodek)
  if ($rxBlockV2.IsMatch($work)) {
    $work = $rxBlockV2.Replace($work, { param($m) $canonical })
    $changed = $true
  }

  # 3) Zwin zduplikowane END (po poprzednich bledach mogly zostac luzem)
  $rxDupEnds = [regex]$endPattern
  if ($rxDupEnds.IsMatch($work)) {
    $work = $rxDupEnds.Replace($work, $endLiteral)
    $changed = $true
  }

  # 4) Opcjonalnie: gole <HeaderLogo/> poza blokami -> owin kanonicznie (globalnie)
  #    Uwaga: jezeli w pliku sa bloki, to i tak beda poprawne po krokach 1-2.
  if ($rxSelfClose.IsMatch($work) -and ($work -notmatch [regex]::Escape($markerV2Start))) {
    $work = $rxSelfClose.Replace($work, { param($m) $canonical })
    $changed = $true
  }

  if ($changed -and $work -ne $orig) {
    $backup = $file + ".bak." + $ts
    Copy-Item -Path $file -Destination $backup -Force
    # LF -> CRLF
    $work = $work -replace "`n","`r`n"
    Set-Content -Path $file -Value $work -Encoding UTF8
    Log ("Patched: " + $file)
    $patchedTotal++
  } else {
    Log ("NO-CHANGE: " + $file)
  }
}

Log ("Patched files total: " + $patchedTotal)
Log "Done. Reload Metro with 'r'."
Write-Host ("Log: " + $logFile)