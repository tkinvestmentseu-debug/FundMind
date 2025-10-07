Param()
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Force -Path $logsDir | Out-Null }
$ts = (Get-Date).ToString("yyyyMMdd-HHmmss")
$log = Join-Path $logsDir ("fundmind-ios-" + $ts + ".log")

function Log($m){
  $line = "[" + (Get-Date).ToString("HH:mm:ss") + "] " + $m
  Write-Host $line
  Add-Content -Path $log -Value $line -Encoding UTF8
}

# --- HARD BOM remover (bytes + \uFEFF at start)
function Clean-BOM([string]$file){
  if (-not (Test-Path $file)) { return }
  [byte[]]$bytes = [System.IO.File]::ReadAllBytes($file)
  if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $bytes = $bytes[3..($bytes.Length-1)]
    [System.IO.File]::WriteAllBytes($file, $bytes)
    Log "Removed BOM (bytes) from $file"
  }
  $c = Get-Content -Raw -Path $file
  $c = $c -replace "^\uFEFF", ""
  Set-Content -Path $file -Value $c -Encoding UTF8
  Log "Ensured no BOM in $file"
}

# --- Robust runner: forces UTF-8 codepage and captures stdout/stderr correctly
function Run-Step([string]$cmd){
  Log ("Run: " + $cmd)
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "cmd.exe"
  $psi.Arguments = "/d /s /c chcp 65001>nul & " + $cmd
  $psi.WorkingDirectory = $projectRoot
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  try {
    # these properties exist in PS7/.NET 6+
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding  = [System.Text.Encoding]::UTF8
  } catch {}
  $p = [System.Diagnostics.Process]::Start($psi)
  $out = $p.StandardOutput.ReadToEnd()
  $err = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  if ($out) { Add-Content -Path $log -Value $out -Encoding UTF8 }
  if ($err) { Add-Content -Path $log -Value $err -Encoding UTF8 }
  [int]$code = [int]$p.ExitCode
  Log ("Exit code: " + $code)
  Start-Process notepad.exe $log
  return $code
}

Log "Start v21"

for ($i=1; $i -le 5; $i++) {
  Log ("---- Attempt " + $i + " ----")

  # 1) PRE: hard-clean BOM (to nie może wracać)
  Clean-BOM (Join-Path $projectRoot "package.json")
  Clean-BOM (Join-Path $projectRoot "app.json")

  # 2) Clean node_modules + lock
  foreach ($p in @("node_modules","package-lock.json")) {
    $fp = Join-Path $projectRoot $p
    if (Test-Path $fp) { Log ("Remove " + $p); Remove-Item $fp -Recurse -Force -ErrorAction SilentlyContinue }
  }

  # 3) npm install
  $code = Run-Step "npm install"
  if ($code -ne 0) { continue }

  # 4) POST: jeszcze raz hard-clean BOM po npm install (bo potrafi wrócić)
  Clean-BOM (Join-Path $projectRoot "package.json")
  Clean-BOM (Join-Path $projectRoot "app.json")

  # 5) start Expo (tunnel)
  $code = Run-Step "npx expo start --tunnel"
  if ($code -eq 0) { Log "Expo started OK"; break }
}

Log "Done v21"
