# Make AI banner smaller & sticky
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$targetFile = Join-Path $projectRoot "app\\index.tsx"
$backupFile = "$targetFile.bak.$(Get-Date -Format yyyyMMddHHmmss)"

if (!(Test-Path $targetFile)) {
  Write-Error "Missing file app\\index.tsx"
  exit 1
}

Copy-Item $targetFile $backupFile -Force
Write-Output ("Backup: " + $backupFile)

$lines = Get-Content $targetFile

# New smaller sticky banner block
[string[]]$newBannerLines = @(
  '      {/* FM-AI-BANNER START */}',
  '      <View style={{ position: "absolute", left: 16, right: 16, bottom: 70 }}>',
  '        <TouchableOpacity className="rounded-2xl bg-gradient-to-r from-purple-400 to-purple-600 p-2 shadow">',
  '          <Text className="text-center text-white font-semibold text-sm">',
  '            FundMind AI (Premium)',
  '          </Text>',
  '        </TouchableOpacity>',
  '      </View>',
  '      {/* FM-AI-BANNER END */}'
)

$out = New-Object System.Collections.Generic.List[string]
$mode = "NORMAL"

foreach ($line in $lines) {
  switch ($mode) {
    "NORMAL" {
      if ($line -match "FM-AI-BANNER START") { $mode = "SKIP_MARKED"; continue }
      if ($line -match "FundMind" -and $line -match "AI") { $mode = "SKIP_TOUCH"; continue }

      if ($line -match "</SafeAreaView>") {
        $out.AddRange($newBannerLines)
        $out.Add($line)
        continue
      }

      $out.Add($line)
    }
    "SKIP_MARKED" {
      if ($line -match "FM-AI-BANNER END") { $mode = "NORMAL" }
      continue
    }
    "SKIP_TOUCH" {
      if ($line -match "</TouchableOpacity>") { $mode = "SKIP_VIEW"; continue }
      continue
    }
    "SKIP_VIEW" {
      if ($line -match "</View>") { $mode = "NORMAL" }
      continue
    }
  }
}

if (-not ($out -match "</SafeAreaView>")) {
  $out.AddRange($newBannerLines)
}

Set-Content -Path $targetFile -Value $out -Encoding UTF8
Write-Output "✅ Smaller sticky AI banner inserted (p-2, text-sm, bottom=70)"
