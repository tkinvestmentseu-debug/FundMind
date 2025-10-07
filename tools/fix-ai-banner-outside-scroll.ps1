# Fix AI banner: move outside ScrollView, add marginBottom
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

# Wyrzuć pasek AI poza ScrollView
if ($content -match "FundMind AI" -and $content -match "ScrollView") {
  $content = $content -replace '(<ScrollView[^{]*\{[^}]*\}>)([\s\S]*)(<TouchableOpacity[\s\S]*FundMind AI[\s\S]*?</TouchableOpacity>)([\s\S]*?</ScrollView>)','$1$2</ScrollView>`r`n`r`n<View style={{ paddingHorizontal: 16, marginBottom: 8 }}>`r`n$3`r`n</View>'
  Set-Content -Path $targetFile -Value $content -Encoding UTF8
  Write-Output "✅ Pasek AI przeniesiony poza ScrollView i ustawiony nad dolnym menu"
} else {
  Write-Output "ℹ️ Brak zmian (może już poprawione)"
}
