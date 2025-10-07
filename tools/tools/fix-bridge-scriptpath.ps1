$bridgeFile = "D:\FundMind\tools\chatgpt-bridge.ps1"
if (-not (Test-Path $bridgeFile)) {
  Write-Host "ERROR: $bridgeFile not found."
  exit 1
}

# Backup
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = "$bridgeFile.bak.$ts"
Copy-Item $bridgeFile $backup -Force
Write-Host "Backup saved -> $backup"

# Patch: popraw $scriptPath = Join-Path $toolsDir ("auto-$ts.ps1") na poprawną wersję
(Get-Content $bridgeFile -Raw -Encoding UTF8) -replace 'Join-Path \$toolsDir \("auto-.*\$ts\.ps1"\)', 'Join-Path $toolsDir "auto-$ts.ps1"' | Set-Content $bridgeFile -Encoding UTF8

Write-Host "✅ Patched $bridgeFile (fixed scriptPath syntax)"

# Test ping
$wrapper = "D:\FundMind\tools\fundmind-ai.ps1"
if (Test-Path $wrapper) {
  Write-Host "Testing FundMind AI wrapper..."
  & $wrapper "Ping test after scriptPath fix" -auto
}
