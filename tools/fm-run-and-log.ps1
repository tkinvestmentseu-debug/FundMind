# fm-run-and-log.ps1 (PS 5.1 compatible)
param(
  [string]$ChildExe,
  [string]$ChildArgs,
  [string]$Stdout,
  [string]$Stderr,
  [string]$Trans
)
Start-Transcript -Path $Trans -Force | Out-Null

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName  = $ChildExe
$psi.Arguments = $ChildArgs
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true

$proc = New-Object System.Diagnostics.Process
$proc.StartInfo = $psi
[void]$proc.Start()

$out = $proc.StandardOutput.ReadToEnd()
$err = $proc.StandardError.ReadToEnd()
$proc.WaitForExit()
$code = $proc.ExitCode

$out | Out-File $Stdout -Encoding UTF8
$err | Out-File $Stderr -Encoding UTF8

Stop-Transcript | Out-Null

Write-Host ""
Write-Host "=== fm-run-and-log: DONE (exit=$code) ==="
Write-Host "stdout: $Stdout"
Write-Host "stderr: $Stderr"
Write-Host "trans : $Trans"
