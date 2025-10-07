Param()
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Force -Path $logsDir | Out-Null }
$ts = (Get-Date).ToString("yyyyMMdd-HHmmss")
$log = Join-Path $logsDir ("fundmind-ios-" + $ts + ".log")

function Log($m) {
  $line = "[" + (Get-Date).ToString("HH:mm:ss") + "] " + $m
  Write-Host $line
  Add-Content -Path $log -Value $line -Encoding UTF8
}

function Clean-BOM($f) {
  if (Test-Path $f) {
    $c = Get-Content $f -Raw
    $c = $c -replace "^\uFEFF", ""
    Set-Content -Path $f -Value $c -Encoding UTF8
    Log "Removed BOM from $f"
  }
}

function Run-Step([string]$cmd) {
  Log "Run: $cmd"
  $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/d /s /c $cmd" `
    -WorkingDirectory $projectRoot -RedirectStandardOutput "$log.out" `
    -RedirectStandardError "$log.err" -PassThru -NoNewWindow
  $proc.WaitForExit()
  if (Test-Path "$log.out") { Get-Content "$log.out" | Tee-Object -FilePath $log -Append }
  if (Test-Path "$log.err") { Get-Content "$log.err" | Tee-Object -FilePath $log -Append }
  Remove-Item "$log.out","$log.err" -ErrorAction SilentlyContinue
  Log "Exit code: $($proc.ExitCode)"
  Start-Process notepad.exe $log
  return $proc.ExitCode
}

Log "Start v20 (loop fixer)"

for ($i = 1; $i -le 5; $i++) {
  Log "---- Attempt $i ----"
  try {
    Clean-BOM (Join-Path $projectRoot "package.json")
    Clean-BOM (Join-Path $projectRoot "app.json")

    foreach ($p in @("node_modules","package-lock.json")) {
      $fp = Join-Path $projectRoot $p
      if (Test-Path $fp) { Log "Remove $p"; Remove-Item $fp -Recurse -Force -ErrorAction SilentlyContinue }
    }

    if ((Run-Step "npm install") -ne 0) { continue }
    if ((Run-Step "npx expo start --tunnel") -eq 0) { Log "Expo started OK"; break }
  }
  catch { Log ("Exception: " + $_.Exception.Message) }
}

Log "Done v20"
