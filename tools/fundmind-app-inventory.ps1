param()

$ErrorActionPreference = "Stop"

function W($s) { Add-Content -Path $outFile -Value $s }

$projectRoot = "D:\FundMind"
$appDir = Join-Path $projectRoot "app"
$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$outFile = Join-Path $logDir ("app-inventory-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".txt")

if (-not (Test-Path $appDir)) {
  $msg = "ERROR: folder 'app' not found at " + $appDir
  Set-Content -Path $outFile -Value $msg -Encoding UTF8
  Start-Process notepad.exe $outFile
  exit 1
}

# Header
Set-Content -Path $outFile -Value ("FundMind app inventory" + [Environment]::NewLine + "Generated: " + (Get-Date -Format "yyyy-MM-dd HH:mm:ss") + [Environment]::NewLine) -Encoding UTF8

# 1) TREE
W ""
W "=== TREE: app directory (files and folders) ==="
$items = Get-ChildItem -Path $appDir -Recurse -Force | Sort-Object FullName
foreach($it in $items){
  $type = if ($it.PSIsContainer) { "[DIR] " } else { "[FILE]" }
  $rel = $it.FullName.Substring($appDir.Length).TrimStart('\')
  if ($it.PSIsContainer) {
    W ($type + " " + $rel)
  } else {
    $size = $it.Length
    $when = $it.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
    W ($type + " " + $rel + "  (" + $size + " bytes, " + $when + ")")
  }
}

# 2) FILE COUNTS BY EXT
W ""
W "=== FILE COUNTS BY EXT ==="
Get-ChildItem -Path $appDir -Recurse -File | Group-Object Extension | Sort-Object Count -Descending | ForEach-Object {
  W ($_.Name + ": " + $_.Count)
}

# 3) HEURISTIC SEARCH (regex; ASCII only)
W ""
W "=== HEURISTIC SEARCH (with 2 lines of context) ==="
$files = Get-ChildItem -Path $appDir -Recurse -File -Include *.tsx,*.ts,*.jsx,*.js | Select-Object -ExpandProperty FullName

# Build regexes using Unescape for diacritics
$rxBudzet = "Bud(?:\u017C|z)et"                        # Budzet/Budzet with z/zbz
$rxMiesiac = "Miesi(?:\u0105|a)c"                      # Miesiac/Miesiac
$rxPLN = "PLN"
$rxWidget = "PremiumBudgetWidget"
$rxWallet = "wallet-outline"
$rxLinear = "LinearGradient"
$rxProgress = "progress|ProgressBar|Animated\.View"
$rxCardTitle = "cardTitleText"
$rxStartScreen = "export\s+default\s+function\s+StartScreen"

$patterns = @(
  @{ Name="PremiumBudgetWidget"; Rx=$rxWidget },
  @{ Name="LinearGradient";     Rx=$rxLinear },
  @{ Name="WalletIcon";         Rx=$rxWallet },
  @{ Name="PLN";                Rx=$rxPLN },
  @{ Name="Budzet";             Rx=$rxBudzet },
  @{ Name="Miesiac";            Rx=$rxMiesiac },
  @{ Name="Progress";           Rx=$rxProgress },
  @{ Name="cardTitleText";      Rx=$rxCardTitle },
  @{ Name="StartScreen";        Rx=$rxStartScreen }
)

foreach($p in $patterns){
  W ""
  W ("--- PATTERN: " + $p.Name + " / " + $p.Rx + " ---")
  try{
    $hits = Select-String -Path $files -Pattern $p.Rx -AllMatches -Context 2,2
    if (-not $hits) { W "(no matches)"; continue }
    foreach($h in $hits){
      W ("FILE: " + $h.Path)
      W ("LINE: " + $h.LineNumber + "  TEXT: " + ($h.Line.Trim()))
      if ($h.Context.PreContext) {
        foreach($pre in $h.Context.PreContext){ W ("  PRE: " + $pre) }
      }
      if ($h.Context.PostContext) {
        foreach($post in $h.Context.PostContext){ W ("  POST: " + $post) }
      }
      W ""
    }
  } catch {
    W ("(error scanning) " + $_.Exception.Message)
  }
}

# 4) TOP OF MAIN INDEX FILES (first 60 lines)
W ""
W "=== HEAD OF CANDIDATE INDEX FILES (first 60 lines) ==="
$idxCandidates = @()
$idxCandidates += Join-Path $appDir "index.tsx"
$idxCandidates += (Get-ChildItem -Path $appDir -Recurse -File -Include index.tsx | Select-Object -ExpandProperty FullName)
$idxCandidates = $idxCandidates | Sort-Object -Unique
foreach($idxf in $idxCandidates){
  if (Test-Path $idxf) {
    W ""
    W ("--- " + $idxf + " ---")
    $head = Get-Content $idxf -TotalCount 60
    $ln = 1
    foreach($l in $head){
      W ($ln.ToString().PadLeft(4) + ": " + $l)
      $ln++
    }
  }
}

# 5) DONE -> open Notepad
Start-Process notepad.exe $outFile
Write-Host ("Inventory written to: " + $outFile)
