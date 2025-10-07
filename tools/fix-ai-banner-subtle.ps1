# Fix AI banner: lift + resize
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

# Popraw styl paska AI
if ($content -match "FundMind AI") {
  $content = $content -replace 'marginBottom:\s*\d+', 'marginBottom: 12'
  $content = $content -replace 'p-4', 'p-3'
  $content = $content -replace 'font-bold', 'font-semibold text-base'
  Set-Content -Path $targetFile -Value $content -Encoding UTF8
  Write-Output "✅ Pasek AI podniesiony i zmniejszony (bardziej subtelny)"
} else {
  Write-Output "ℹ️ Nie znaleziono paska AI do edycji"
}
