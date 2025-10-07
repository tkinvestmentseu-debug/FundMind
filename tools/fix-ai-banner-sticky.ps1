# Sticky AI banner: always above bottom tab bar
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
      {/* Pasek AI sticky nad dolnym menu */}
      <View style={{ position: "absolute", left: 16, right: 16, bottom: 70 }}>
        <TouchableOpacity className="rounded-2xl bg-gradient-to-r from-purple-400 to-purple-600 p-3 shadow">
          <Text className="text-center text-white font-semibold text-base">
            FundMind AI (Premium)
          </Text>
        </TouchableOpacity>
      </View>
"@

  # usuń stary blok z AI i wklej sticky
  $content = $content -replace '<View[^>]*>\s*<TouchableOpacity[\s\S]*?FundMind AI[\s\S]*?</TouchableOpacity>\s*</View>',$newBanner

  Set-Content -Path $targetFile -Value $content -Encoding UTF8
  Write-Output "✅ Pasek AI ustawiony sticky nad dolnym menu"
} else {
  Write-Output "ℹ️ Nie znaleziono paska AI do edycji"
}
