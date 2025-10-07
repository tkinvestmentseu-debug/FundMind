param(
  [string]$ProjectRoot = "D:\\FundMind",
  [string]$Target = "D:\\FundMind\\app\\(tabs)\\index.tsx"
)

$ErrorActionPreference = "Stop"

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$logsDir = Join-Path $ProjectRoot "logs"
if (-not (Test-Path $logsDir)) { New-Item -Path $logsDir -ItemType Directory | Out-Null }
$logFile = Join-Path $logsDir ("fix-jsx-balance-" + $ts + ".log")

function Log([string]$msg) {
  $line = "[" + (Get-Date -Format "HH:mm:ss") + "] " + $msg
  $line | Tee-Object -FilePath $logFile -Append
}

Log "Start JSX balance fixer. Target: $Target"

if (-not (Test-Path $Target)) {
  Log "ERROR: Target file not found."
  throw "Target not found"
}

# Read file (LF normalization for processing)
$text = Get-Content -Path $Target -Raw
$lf   = $text -replace "`r`n","`n"

# ---- SEARCH PHASE ----
# Report markers and logos
$lines = $lf -split "`n"
for ($i=0; $i -lt $lines.Count; $i++) {
  $ln = $i + 1
  if ($lines[$i] -match "HeaderLogo|FUNDLOGO_WRAP_v1|FUNDLOGO_WRAP_v2|<ScrollView|</ScrollView>|<View|</View>") {
    Log ("[" + $ln + "] " + $lines[$i].Trim())
  }
}

# Count ScrollView / View
$openSV  = ([regex]::Matches($lf, '<ScrollView\b[^>]*>')).Count
$closeSV = ([regex]::Matches($lf, '</ScrollView>')).Count
$openV   = ([regex]::Matches($lf, '<View(?![^>]*\/)>')).Count  # non self-closing
$closeV  = ([regex]::Matches($lf, '</View>')).Count
Log ("Counts BEFORE: ScrollView open=" + $openSV + " close=" + $closeSV + " | View open=" + $openV + " close=" + $closeV)

# ---- FIX 1: remove stray </View> immediately after FUNDLOGO_WRAP_v2 END ----
$markerEnd = '{/* FUNDLOGO_WRAP_v2 END */}'
$patternEndPlusClose = [regex]::Escape($markerEnd) + '\s*(?:\r?\n)?\s*</View>'
$lf = [regex]::Replace($lf, $patternEndPlusClose, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $markerEnd }, 0)

# ---- FIX 2: balance <View> / </View> by removing excess closers that would underflow the stack ----
# Tokenize tags (keep positions)
$tagRx = New-Object System.Text.RegularExpressions.Regex '(<View\b[^>]*?/>)|(<View\b[^>]*?>)|(</View>)', ([System.Text.RegularExpressions.RegexOptions]::Singleline)
$sb = New-Object System.Text.StringBuilder
$pos = 0
$stack = 0
$removals = @()

$matches = $tagRx.Matches($lf)
foreach ($m in $matches) {
  # Append text up to this tag
  $null = $sb.Append($lf.Substring($pos, $m.Index - $pos))
  $tag = $m.Value
  if ($m.Groups[1].Success) {
    # self-closing <View .../>
    $null = $sb.Append($tag)
  } elseif ($m.Groups[2].Success) {
    # opening <View>
    $stack += 1
    $null = $sb.Append($tag)
  } elseif ($m.Groups[3].Success) {
    # closing </View>
    if ($stack -gt 0) {
      $stack -= 1
      $null = $sb.Append($tag)
    } else {
      # underflow -> drop this closing tag
      $removals += $m.Index
      # do NOT append
    }
  }
  $pos = $m.Index + $m.Length
}
# Append remainder
if ($pos -lt $lf.Length) { $null = $sb.Append($lf.Substring($pos)) }
$lf = $sb.ToString()

if ($removals.Count -gt 0) { Log ("Removed stray </View> count: " + $removals.Count) }

# ---- FIX 3: ensure at most one closing </ScrollView> for the first opening; if missing, add one at file end ----
$openSV  = ([regex]::Matches($lf, '<ScrollView\b[^>]*>')).Count
$closeSV = ([regex]::Matches($lf, '</ScrollView>')).Count

if ($openSV -ge 1 -and $closeSV -eq 0) {
  Log "No </ScrollView> found while an opening exists -> appending one at EOF."
  $lf = $lf.TrimEnd() + "`n</ScrollView>`n"
} elseif ($closeSV -gt $openSV) {
  Log ("Too many </ScrollView>: " + $closeSV + " vs open " + $openSV + " -> trimming extras at EOF")
  # remove extra closings from end
  $needTrim = $closeSV - $openSV
  for ($k=0; $k -lt $needTrim; $k++) {
    $lf = [regex]::Replace($lf, '</ScrollView>\s*$', '', 1)
  }
}

# ---- REPORT AFTER ----
$openSV2  = ([regex]::Matches($lf, '<ScrollView\b[^>]*>')).Count
$closeSV2 = ([regex]::Matches($lf, '</ScrollView>')).Count
$openV2   = ([regex]::Matches($lf, '<View(?![^>]*\/)>')).Count
$closeV2  = ([regex]::Matches($lf, '</View>')).Count
Log ("Counts AFTER : ScrollView open=" + $openSV2 + " close=" + $closeSV2 + " | View open=" + $openV2 + " close=" + $closeV2)

# ---- WRITE BACKUP + SAVE ----
$backup = $Target + ".bak." + $ts
Copy-Item -Path $Target -Destination $backup -Force
# restore CRLF
$out = $lf -replace "`n","`r`n"
Set-Content -Path $Target -Value $out -Encoding UTF8
Log ("Patched: " + $Target)
Log "Done. Reload Metro with 'r'."
Write-Host ("Log: " + $logFile)