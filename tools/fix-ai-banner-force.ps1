# Force rewrite AI banner block as sticky
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

$lines = Get-Content $targetFile
$out = New-Object System.Collections.Generic.List[string]

$newBanner = @"
      {/* Pasek AI sticky nad dolnym menu */}
      <View style={{ position: "absolute", left: 16, right: 16, bottom: 70 }}>
        <TouchableOpacity className="rounded-2xl bg-gradient-to-r from-purple-400 to-purple-600 p-3 shadow">
          <Text className="text-center text-white font-semibold text-base">
            FundMind AI (Premium)
          </Text>
        </TouchableOpacity>
      </View>
"@ -split "`r?`n"

foreach ($line in $lines) {
  # pomiń stare linie z AI
  if ($line -match "FundMind AI") { continue }
  if ($line -match "</SafeAreaView>") {
    # przed zamknięciem SafeAreaView wstrzyknij sticky pasek
    $out.AddRange($newBanner)
  }
  $out.Add($line)
}

Set-Content -Path $targetFile -Value $out -Encoding UTF8
Write-Output "✅ Pasek AI został wstawiony sticky nad dolnym menu"
