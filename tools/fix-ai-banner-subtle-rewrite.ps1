# Rewrite AI banner block (FundMind)
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
$newBlock = @"
<View style={{ paddingHorizontal: 16, marginBottom: 12 }}>
  <TouchableOpacity className="rounded-2xl bg-gradient-to-r from-purple-400 to-purple-600 p-3 shadow">
    <Text className="text-center text-white font-semibold text-base">
      FundMind AI (Premium)
    </Text>
  </TouchableOpacity>
</View>
"@ -split "`r?`n"

$out = New-Object System.Collections.Generic.List[string]
$skip = $false

foreach ($line in $lines) {
  if ($line -match "FundMind" -and $line -match "Premium") {
    # start nadpisywania
    $skip = $true
    $out.AddRange($newBlock)
    continue
  }
  if ($skip -and $line -match "</TouchableOpacity>") {
    # koniec starego bloku – pomijamy
    $skip = $false
    continue
  }
  if (-not $skip) {
    $out.Add($line)
  }
}

Set-Content -Path $targetFile -Value $out -Encoding UTF8
Write-Output "✅ Pasek AI został nadpisany na subtelny wariant"
