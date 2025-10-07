param(
  [string]$ProjectRoot = "D:\\FundMind",
  [double]$Scale = 1.5,
  [int]$Offset = -16
)

using namespace System.Text
using namespace System.Text.RegularExpressions

$ErrorActionPreference = "Stop"

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$logsDir = Join-Path $ProjectRoot "logs"
if (-not (Test-Path $logsDir)) { New-Item -Path $logsDir -ItemType Directory | Out-Null }
$logFile = Join-Path $logsDir ("fix-logo-wrapper-v2c-" + $ts + ".log")

function Log([string]$msg) {
  $line = ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $msg)
  $line | Tee-Object -FilePath $logFile -Append
}

Log "Start fix-logo-wrapper v2c. Root: $ProjectRoot, scale=$Scale, marginTop=$Offset"

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

# Build safe regexes with Escape() and proper constructors
$patV1Block = [Regex]::Escape($markerV1Start) + '[\s\S]*?' + [Regex]::Escape($markerV1End)
$patV2Block = [Regex]::Escape($markerV2Start) + '[\s\S]*?' + [Regex]::Escape($markerV2End)
$rxV1Block  = [Regex]::new($patV1Block, [RegexOptions]::Singleline)
$rxV2Block  = [Regex]::new($patV2Block, [RegexOptions]::Singleline)

# END dupes (collapse multiple END to one)
$patEndDup  = [Regex]::Escape($markerV2End) + '(?:\s*(?:\r?\n)?\s*' + [Regex]::Escape($markerV2End) + ')+'
$rxEndDup   = [Regex]::new($patEndDup, [RegexOptions]::Singleline)

# Orphan END (END without a preceding START on the same or previous line) -> remove
$patEndOrphan = '(^|\r?\n)\s*' + [Regex]::Escape($markerV2End) + '\s*(?!(.*' + [Regex]::Escape($markerV2Start) + '))'
$rxEndOrphan  = [Regex]::new($patEndOrphan)

# Self-closing HeaderLogo
$rxSelfClose = [Regex]::new('<HeaderLogo([^>]*)\/>', [RegexOptions]::Singleline)

$patchedTotal = 0

foreach ($file in $targets) {
  $orig = Get-Content -Path $file -Raw
  $work = $orig
  $changed = $false

  # Normalize newlines to LF
  $work = $work -replace "`r`n","`n"

  # 0) Collapse duplicate END markers globally
  if ($rxEndDup.IsMatch($work)) {
    $work = $rxEndDup.Replace($work, $markerV2End)
    $changed = $true
  }

  # 1) Replace ALL v1 blocks with canonical v2
  if ($rxV1Block.IsMatch($work)) {
    $work = $rxV1Block.Replace($work, { param($m) $canonical })
    $changed = $true
  }

  # 2) Replace ALL v2 blocks with canonical (rebuild internals cleanly)
  if ($rxV2Block.IsMatch($work)) {
    $work = $rxV2Block.Replace($work, { param($m) $canonical })
    $changed = $true
  }

  # 3) Remove any orphan END left behind
  if ($rxEndOrphan.IsMatch($work)) {
    $work = $rxEndOrphan.Replace($work, "`n")
    $changed = $true
  }

  # 4) Wrap any remaining self-closing HeaderLogo not already within markers
  if ($rxSelfClose.IsMatch($work) -and ($work -notmatch [Regex]::Escape($markerV2Start))) {
    $work = $rxSelfClose.Replace($work, { param($m) $canonical })
    $changed = $true
  }

  if ($changed -and $work -ne $orig) {
    $backup = $file + ".bak." + $ts
    Copy-Item -Path $file -Destination $backup -Force
    # Restore CRLF
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