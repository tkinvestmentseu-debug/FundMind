$ErrorActionPreference = "Stop"
$pkgPath = "D:\FundMind\package.json"
if (-not (Test-Path $pkgPath)) {
  Write-Output "[strip-bom] package.json not found: $pkgPath"
  exit 1
}
# PS7-safe: use -AsByteStream
[byte[]]$bytes = Get-Content -Path $pkgPath -AsByteStream -Raw
if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
  Write-Output "[strip-bom] BOM detected, stripping..."
  $bytes = $bytes[3..($bytes.Length-1)]
} else {
  Write-Output "[strip-bom] No BOM detected."
}
[System.IO.File]::WriteAllBytes($pkgPath, $bytes)
Write-Output "[strip-bom] package.json cleaned and saved."
Write-Output ""
Write-Output "--- Preview (first 5 lines) ---"
Get-Content -Path $pkgPath -Encoding UTF8 | Select-Object -First 5
