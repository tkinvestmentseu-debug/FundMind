Param()
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir = Join-Path $projectRoot "logs"
if(-not (Test-Path $logsDir)){ New-Item -ItemType Directory -Force -Path $logsDir | Out-Null }
$ts = (Get-Date).ToString("yyyyMMdd-HHmmss")
$log = Join-Path $logsDir ("fundmind-ios-" + $ts + ".log")
function Log($m){ $line = "[" + (Get-Date).ToString("HH:mm:ss") + "] " + $m; Write-Host $line; Add-Content -Path $log -Value $line -Encoding UTF8 }
function Invoke-CmdLine([string]$cmd){
  Log ("Run: " + $cmd)
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "cmd.exe"
  $psi.Arguments = "/d /s /c " + $cmd
  $psi.WorkingDirectory = $projectRoot
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.CreateNoWindow = $true
  $proc = [System.Diagnostics.Process]::Start($psi)
  $out = $proc.StandardOutput.ReadToEnd()
  $err = $proc.StandardError.ReadToEnd()
  $proc.WaitForExit()
  if($out){ Add-Content -Path $log -Value $out -Encoding UTF8 }
  if($err){ Add-Content -Path $log -Value $err -Encoding UTF8 }
  if($proc.ExitCode -eq 0){ Log ("OK: " + $cmd) } else { throw ("FAIL (" + $cmd + ") exit " + $proc.ExitCode) }
}
Log "Start v9"
Set-Location $projectRoot
Invoke-CmdLine "npm install"
Log "Starting Expo dev server (tunnel)..."
$extra = ""
if($env:CLEAR -eq "1"){ $extra = " --clear"; Log "Metro cache clear enabled" }
& cmd.exe /c "npx expo start --tunnel$extra"
