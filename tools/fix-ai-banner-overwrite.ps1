# Overwrite AI banner block
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

# Zastąp cały blok TouchableOpacity z FundMind AI nowym View
$pattern = '<TouchableOpacity[\s\S]*?FundMind AI[\s\S]*?</TouchableOpacity>'
$replacement = @"
<View style={{ paddingHorizontal: 16, marginBottom: 12 }}>
  <TouchableOpacity className="rounded-2xl bg-gradient-to-r from-purple-400 to-purple-600 p-3 shadow">
    <Text className="text-center text-white font-semibold text-base">
      FundMind AI (Premium)
    </Text>
  </TouchableOpacity>
</View>
"@

if ($content -match "FundMind AI") {
  $newContent = [regex]::Replace($content, $pattern, $replacement, 1, "Singleline")
  Set-Content -Path $targetFile -Value $newContent -Encoding UTF8
  Write-Output "✅ Pasek AI nadpisany (subtelny + podniesiony)"
} else {
  Write-Output "ℹ️ Nie znaleziono wzorca z FundMind AI"
}
