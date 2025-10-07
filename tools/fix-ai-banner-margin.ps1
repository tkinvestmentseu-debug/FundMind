# Fix AI banner margin (FundMind)
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$targetFile = Join-Path $projectRoot "app\\index.tsx"
$backupFile = "$targetFile.bak.$(Get-Date -Format yyyyMMddHHmmss)"

if (!(Test-Path $targetFile)) {
  Write-Error "Plik app\\index.tsx nie istnieje"
  exit 1
}

Copy-Item $targetFile $backupFile -Force
Write-Output "Backup zapisany: $backupFile"

$content = Get-Content $targetFile -Raw

# Szukamy kontenera AI i dodajemy mb-4
$pattern = '(<TouchableOpacity[^>]*className="[^"]*)'
$replacement = '$1 mb-4'

if ($content -match "FundMind AI" -and $content -notmatch "mb-4") {
  $newContent = [regex]::Replace($content, $pattern, $replacement, 1)
  Set-Content -Path $targetFile -Value $newContent -Encoding UTF8
  Write-Output "OK: Dodano odstęp pod paskiem AI"
} else {
  Write-Output "INFO: Już zawiera mb-4 lub brak wzorca"
}
