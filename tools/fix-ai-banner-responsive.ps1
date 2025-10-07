# Fix AI banner: responsive SafeAreaView bottom padding
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

# Dodaj import Dimensions jeśli go nie ma
if ($content -notmatch "Dimensions") {
  $content = $content -replace 'import {([^}]*)} from "react-native";','import {`$1, Dimensions} from "react-native";'
}

# Dodaj obliczenie odstępu jeśli nie istnieje
if ($content -notmatch "bottomSpacing") {
  $content = $content -replace '(import .*react-native.*\r?\n)','$1`r`nconst screenHeight = Dimensions.get("window").height;`r`nconst bottomSpacing = Math.max(8, screenHeight * 0.01);`r`n'
}

# Zmień SafeAreaView -> użyj bottomSpacing
if ($content -match "<SafeAreaView" -and $content -notmatch "bottomSpacing") {
  $content = $content -replace '<SafeAreaView([^>]*)>','<SafeAreaView style={{ flex: 1, paddingBottom: bottomSpacing }}>'
}

Set-Content -Path $targetFile -Value $content -Encoding UTF8
Write-Output "✅ Responsywny odstęp (min 8px, ~1% ekranu) ustawiony"
