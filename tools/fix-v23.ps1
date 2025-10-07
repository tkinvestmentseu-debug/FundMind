$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logDir = "$projectRoot\logs"
if (!(Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$log = "$logDir\fix-v23-$timestamp.log"

function Log($msg) {
  $ts = Get-Date -Format "HH:mm:ss"
  Add-Content -Path $log -Value "[$ts] $msg"
  Write-Host "[$ts] $msg"
}

function Remove-BOM($file) {
  if (Test-Path $file) {
    $bytes = [System.IO.File]::ReadAllBytes($file)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
      $clean = $bytes[3..($bytes.Length-1)]
      [System.IO.File]::WriteAllBytes($file, $clean)
      Log "Removed BOM (bytes) from $file"
    }
    $text = Get-Content -Path $file -Raw
    $text = $text -replace "^\uFEFF",""
    Set-Content -Path $file -Value $text -Encoding UTF8
    Log "Ensured no BOM in $file"
  }
}

function Run-Step([string]$cmd) {
  Log "Run: $cmd"
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "cmd.exe"
  $psi.Arguments = "/d /s /c $cmd"
  $psi.WorkingDirectory = $projectRoot
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.UseShellExecute = $false
  $proc = New-Object System.Diagnostics.Process
  $proc.StartInfo = $psi
  $proc.Start() | Out-Null
  $out = $proc.StandardOutput.ReadToEnd()
  $err = $proc.StandardError.ReadToEnd()
  $proc.WaitForExit()
  Add-Content -Path $log -Value $out
  Add-Content -Path $log -Value $err
  Log "Exit code: $($proc.ExitCode)"
  if ($proc.ExitCode -ne 0) { throw "Step failed: $cmd" }
}

Log "Start v23 (BOM watchdog + retry)"
Copy-Item "$projectRoot\package.json" "$projectRoot\package.json.bak.$timestamp" -Force
Copy-Item "$projectRoot\app.json" "$projectRoot\app.json.bak.$timestamp" -Force
Remove-BOM "$projectRoot\package.json"
Remove-BOM "$projectRoot\app.json"

if (Test-Path "$projectRoot\node_modules") { Remove-Item -Recurse -Force "$projectRoot\node_modules" }
if (Test-Path "$projectRoot\package-lock.json") { Remove-Item -Force "$projectRoot\package-lock.json" }
Run-Step "npm install"
Remove-BOM "$projectRoot\package.json"
Remove-BOM "$projectRoot\app.json"

for ($i=1; $i -le 3; $i++) {
  Log "---- Expo Attempt $i ----"
  try {
    Run-Step "npx expo start --tunnel"
    break
  } catch {
    Log "Expo failed on attempt $i : $_"
    Start-Sleep -Seconds 2
    Remove-BOM "$projectRoot\package.json"
    Remove-BOM "$projectRoot\app.json"
  }
}

Log "Done v23"
Start-Process notepad.exe $log
