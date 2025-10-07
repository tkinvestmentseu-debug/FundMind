# Hard replace AI banner with subtle version
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

if ($content -match "FundMind AI") {
  $newBanner = @"
<View style={{ paddingHorizontal: 16, marginBottom: 12 }}>
  <TouchableOpacity className="rounded-2xl bg-gradient-to-r from-purple-400 to-purple-600 p-3 shadow">
    <Text className="text-center text-white font-semibold text-base">
      FundMind AI (Premium)
    </Text>
  </TouchableOpacity>
</View>
"@

  # Zamień cały stary blok na nowy
  $content = $content -replace '<TouchableOpacity[\s\S]*?FundMind AI[\s\S]*?</TouchableOpacity>',$newBanner

  Set-Content -Path $targetFile -Value $content -Encoding UTF8
  Write-Output "✅ Pasek AI został podmieniony na subtelny wariant"
} else {
  Write-Output "ℹ️ Nie znaleziono wzorca 'FundMind AI' w pliku"
}
