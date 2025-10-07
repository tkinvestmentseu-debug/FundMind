$ErrorActionPreference="Stop"
$backup = "$PSScriptRoot"
$target = "D:\FundMind"

Write-Host "[*] Stopuję Node/Expo..."
Get-Process node -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-Process expo -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Set-Location "D:\"
if (Test-Path $target) { Remove-Item -Recurse -Force $target }

Write-Host "[*] Odtwarzam: $backup -> $target"
$null = robocopy $backup $target /E /COPY:DAT /R:2 /W:1 /XJ /MT:16
if ($LASTEXITCODE -gt 7) { throw "Robocopy failed (exit $LASTEXITCODE)" }

Set-Location $target
if (-not (Test-Path "node_modules")) { npm install }
npx expo start --clear
