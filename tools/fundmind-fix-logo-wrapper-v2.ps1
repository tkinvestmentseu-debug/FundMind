param(
  [string]$ProjectRoot = "D:\\FundMind",
  [double]$Scale = 1.5,
  [int]$Offset = -16
)

$ErrorActionPreference = "Stop"

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$logsDir = Join-Path $ProjectRoot "logs"
if (-not (Test-Path $logsDir)) { New-Item -Path $logsDir -ItemType Directory | Out-Null }
$logFile = Join-Path $logsDir ("fix-logo-wrapper-v2-" + $ts + ".log")

function Log([string]$msg) {
  $line = ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $msg)
  $line | Tee-Object -FilePath $logFile -Append
}

Log "Start fix-logo-wrapper v2. Root: $ProjectRoot, scale=$Scale, marginTop=$Offset"

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

# Canonical wrapper
$canonical = $markerV2Start + "`n" +
"<View style={{ transform:[{ scale:" + $Scale + " }], marginTop:" + $Offset + ", alignSelf:'center' }}>" + "`n" +
"  <HeaderLogo />" + "`n" +
"</View>" + "`n" +
$markerV2End + "`n"

# Tokens to simplify dedupe
$TOKEN = "<<<FLOGO_V2_BLOCK>>>"

# Regexes
$rxV1Block   = [regex]::Escape($markerV1Start) + "[\\s\\S]*?" + [regex]::Escape($markerV1End)
$rxV2Block   = [regex]::Escape($markerV2Start) + "[\\s\\S]*?" + [regex]::Escape($markerV2End)
$rxSelfClose = "<HeaderLogo([^>]*)\\/>"           # self-closing tag
$rxSimpleWrap= "<View\\s+style=\\{\\{[\\s\\S]*?\\}\\}>\\s*<HeaderLogo\\s*\\/>\\s*<\\/View>"  # minimal wrapper

# Orphan fixes around markers
$rxEndPlusExtraClose = "(\{\/\\*\\s*FUNDLOGO_WRAP_v2\\s*END\\s*\\*\/\})\\s*(\\r?\\n)\\s*<\\/View>"
$rxDupEnds = "(\{\/\\*\\s*FUNDLOGO_WRAP_v2\\s*END\\s*\\*\/\})(\\s*(\\r?\\n)\\s*)+\{\/\\*\\s*FUNDLOGO_WRAP_v2\\s*END\\s*\\*\/\}"

$patchedTotal = 0

foreach ($file in $targets) {
  $orig = Get-Content -Path $file -Raw
  $work = $orig
  $changed = $false

  # 0) Normalize CRLF
  $work = $work -replace "`r`n", "`n"

  # 1) Replace any existing v2 blocks with token
  if ($work -match $rxV2Block) {
    $work = [regex]::Replace($work, $rxV2Block, $TOKEN, 0)
    $changed = $true
  }

  # 2) Replace any v1 blocks with token (upgrade)
  if ($work -match $rxV1Block) {
    $work = [regex]::Replace($work, $rxV1Block, $TOKEN, 0)
    $changed = $true
  }

  # 3) Replace ALL self-closing HeaderLogo with token
  if ($work -match $rxSelfClose) {
    $work = [regex]::Replace($work, $rxSelfClose, $TOKEN, 0)
    $changed = $true
  }

  # 4) Replace simple one-line wrappers with token
  if ($work -match $rxSimpleWrap) {
    $work = [regex]::Replace($work, $rxSimpleWrap, $TOKEN, 0)
    $changed = $true
  }

  # 5) Collapse multiple tokens into one token
  $rxMultiToken = "($([regex]::Escape($TOKEN))(\s*)?){2,}"
  if ($work -match $rxMultiToken) {
    $work = [regex]::Replace($work, $rxMultiToken, $TOKEN, 0)
    $changed = $true
  }

  # 6) Replace token with canonical wrapper
  if ($work -match [regex]::Escape($TOKEN)) {
    $work = $work -replace [regex]::Escape($TOKEN), [System.Text.RegularExpressions.Regex]::Escape($canonical).Replace("\\", "\")
    $work = $work -replace "\\n", "`n"
    $changed = $true
  }

  # 7) Remove orphaned extra </View> just after END
  if ($work -match $rxEndPlusExtraClose) {
    $work = [regex]::Replace($work, $rxEndPlusExtraClose, '$1$2', 0)
    $changed = $true
  }

  # 8) Remove duplicate END markers back-to-back
  if ($work -match $rxDupEnds) {
    $work = [regex]::Replace($work, $rxDupEnds, '$1', 0)
    $changed = $true
  }

  if ($changed -and $work -ne $orig) {
    $backup = $file + ".bak." + $ts
    Copy-Item -Path $file -Destination $backup -Force
    Set-Content -Path $file -Value ($work -replace "`n","`r`n") -Encoding UTF8
    Log ("Patched: " + $file)
    $patchedTotal++
  } else {
    Log ("NO-CHANGE: " + $file)
  }
}

Log ("Patched files total: " + $patchedTotal)
Log "Done. Reload Metro with 'r'."
Write-Host ("Log: " + $logFile)