param(
  [string]$ProjectRoot = "D:\FundMind"
)

$ErrorActionPreference = "Stop"

# Init
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$logsDir = Join-Path $ProjectRoot "logs"
if (-not (Test-Path $logsDir)) { New-Item -Path $logsDir -ItemType Directory | Out-Null }
$logFile = Join-Path $logsDir ("logo-search-and-boost-" + $ts + ".log")

function Log([string]$msg) {
  $line = ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $msg)
  $line | Tee-Object -FilePath $logFile -Append
}

Log "Start logo search & boost. Root: $ProjectRoot"

# Paths
$appDir = Join-Path $ProjectRoot "app"
if (-not (Test-Path $appDir)) {
  Log "ERROR: app directory not found: $appDir"
  throw "app dir missing"
}

# Search phase: find files that likely use logo
$patterns = @(
  "HeaderLogo",
  "logo\.png",
  "logo\.jpg",
  "logo\.jpeg",
  "logo\.webp",
  "logo\.svg"
)

$files = Get-ChildItem -Path $appDir -Recurse -File -Include *.tsx,*.ts
$hits = @()

foreach ($f in $files) {
  foreach ($pat in $patterns) {
    if (Select-String -Path $f.FullName -Pattern $pat -SimpleMatch:$false -Quiet) {
      $hits += $f.FullName
      break
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

# Show snippets with line numbers for HeaderLogo specifically
Log "Snippets for 'HeaderLogo' (if any):"
foreach ($f in $hits) {
  $matches = Select-String -Path $f -Pattern "HeaderLogo" -Context 0,1 -ErrorAction SilentlyContinue
  if ($matches) {
    Log ("--- " + $f)
    foreach ($m in $matches) {
      $ln = $m.LineNumber
      $txt = $m.Line.Trim()
      Log ("  [" + $ln + "] " + $txt)
    }
  }
}

# Patch phase:
# Goal: make the logo bigger (scale 1.25) and move it higher (marginTop -12)
# Strategy: wrap the first <HeaderLogo .../> with a View having transform scale and negative marginTop.
# Idempotent marker: FUNDLOGO_WRAP_v1

$wrapMarkerStart = "{/* FUNDLOGO_WRAP_v1 START */}"
$wrapMarkerEnd   = "{/* FUNDLOGO_WRAP_v1 END */}"

$newWrap = @"
$wrapMarkerStart
<View style={{ transform:[{{ scale:1.25 }}], marginTop:-12, alignSelf:'center' }}>
  <HeaderLogo />
</View>
$wrapMarkerEnd
"@

# Regexes
$rxSelfClose = '<HeaderLogo([^>]*)\/>'               # <HeaderLogo .../>
$rxSimpleWrap = '<View\s+style=\{\{[\s\S]*?\}\}>\s*<HeaderLogo\s*\/>\s*<\/View>'  # basic wrapper

# Targets: only .tsx/.ts where HeaderLogo is present
$targetFiles = $hits | Where-Object {
  Select-String -Path $_ -Pattern "HeaderLogo" -Quiet
}

if ($targetFiles.Count -eq 0) {
  Log "No HeaderLogo tags found to patch."
} else {
  Log ("Candidates to patch: " + $targetFiles.Count)
}

foreach ($file in $targetFiles) {
  try {
    if (-not (Test-Path $file)) {
      Log ("SKIP missing: " + $file)
      continue
    }

    $txt = Get-Content -Path $file -Raw -ErrorAction Stop

    if ($txt -match [regex]::Escape($wrapMarkerStart)) {
      Log ("SKIP already wrapped: " + $file)
      continue
    }

    $backup = $file + ".bak." + $ts
    Copy-Item -Path $file -Destination $backup -Force
    Log ("Backup: " + $backup)

    $out = $txt

    # Case A: replace first self-closing HeaderLogo with our wrapped block
    if ($out -match $rxSelfClose) {
      $out = [regex]::Replace($out, $rxSelfClose, $newWrap, 1)
    } else {
      # Case B: sometimes HeaderLogo is already inside a View wrapper: replace that wrapper
      if ($out -match $rxSimpleWrap) {
        $out = [regex]::Replace($out, $rxSimpleWrap, $newWrap, 1)
      }
    }

    if ($out -ne $txt) {
      Set-Content -Path $file -Value $out -Encoding UTF8
      Log ("Patched: " + $file)
      Write-Host ("OK: updated " + $file)
    } else {
      Log ("NO-CHANGE: " + $file + " (pattern not matched)")
      Write-Host ("NOTE: " + $file + " - no HeaderLogo variant matched for replacement.")
    }
  } catch {
    Log ("ERROR patching " + $file + ": " + $_.Exception.Message)
    Write-Host ("ERROR: " + $file + " -> " + $_.Exception.Message)
  }
}

Log "Done. Press 'r' in Metro to reload."
Write-Host ("Log: " + $logFile)