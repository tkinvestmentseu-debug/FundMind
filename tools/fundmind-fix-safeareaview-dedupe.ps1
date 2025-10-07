param([string]$ProjectRoot,[string]$LogPath)
function Log($m){$l="[ $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") ] $m";$l|Out-File -FilePath $LogPath -Append -Encoding UTF8;Write-Host $l}

Log "== START =="
# 0) Ensure _data/transactions.ts has default export (silences route warning)
$tx = Join-Path $ProjectRoot "app\_data\transactions.ts"
if(Test-Path $tx){
  $raw = Get-Content $tx -Raw -Encoding UTF8
  if($raw -notmatch "export\s+default\s+"){
    Copy-Item $tx "$tx.bak.$(Get-Date -Format yyyyMMdd-HHmmss)" -Force
    $add = "`r`n/** auto-added to satisfy expo-router */`r`nexport default function DataRoutePlaceholder(){return null;}`r`n"
    Set-Content $tx -Value ($raw+$add) -Encoding UTF8
    Log "Added default export to _data/transactions.ts"
  } else { Log "Default export already present in _data/transactions.ts" }
} else { Log "File not found (skip): app\\_data\\transactions.ts" }

# 1) Helpers
$rxIgnore = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
function RemoveSafeAreaFromRNImports([string]$text){
  $patterns = @(
    "import\s*\{([^}]*)\}\s*from\s*'react-native';?",
    "import\s*\{([^}]*)\}\s*from\s*""react-native"";?"
  )
  foreach($p in $patterns){
    $text = [regex]::Replace($text,$p,{
      param($m)
      $inside = $m.Groups[1].Value
      $tokens = @()
      foreach($tok in ($inside -split ",")){ $t=$tok.Trim(); if($t.Length -gt 0){ $tokens += $t } }
      $filtered = @($tokens | Where-Object { $_ -ne 'SafeAreaView' })
      if($filtered.Count -eq $tokens.Count){ return $m.Value }      # no change
      if($filtered.Count -eq 0){ return "" }                         # drop whole import
      $newlist = [string]::Join(", ", $filtered)
      return "import { $newlist } from 'react-native';"
    }, $rxIgnore)
  }
  return $text
}
function ConsolidateSafeAreaContextImports([string]$text){
  $p1 = "import\s*\{([^}]*)\}\s*from\s*'react-native-safe-area-context';?"
  $p2 = "import\s*\{([^}]*)\}\s*from\s*""react-native-safe-area-context"";?"
  $m1 = [regex]::Matches($text,$p1,$rxIgnore)
  $m2 = [regex]::Matches($text,$p2,$rxIgnore)
  $had = ($m1.Count -gt 0 -or $m2.Count -gt 0)

  $names = New-Object System.Collections.Generic.List[string]
  foreach($m in $m1){ foreach($tok in ($m.Groups[1].Value -split ",")){ $t=$tok.Trim(); if($t.Length -gt 0){ [void]$names.Add($t) } } }
  foreach($m in $m2){ foreach($tok in ($m.Groups[1].Value -split ",")){ $t=$tok.Trim(); if($t.Length -gt 0){ [void]$names.Add($t) } } }

  # Remove all existing safe-area-context imports
  $text = [regex]::Replace($text,$p1,"",$rxIgnore)
  $text = [regex]::Replace($text,$p2,"",$rxIgnore)

  # Detect usage of SafeAreaView
  $usesSAV = ($text -match "\bSafeAreaView\b")

  # Ensure SafeAreaView present if used
  if($usesSAV -and -not ($names -contains 'SafeAreaView')){ [void]$names.Add('SafeAreaView') }

  # If nothing to import and no previous imports existed, do not add new line
  if($names.Count -eq 0 -and -not $usesSAV -and -not $had){ return $text }

  # Consolidate unique, keep order
  $unique = @()
  foreach($n in $names){ if(-not ($unique -contains $n)){ $unique += $n } }
  if($unique.Count -eq 0){ return $text }

  $joined = [string]::Join(", ", $unique)
  $line = "import { $joined } from 'react-native-safe-area-context';"
  return ($line + "`r`n" + $text)
}

# 2) Process all TSX files under app/
$files = Get-ChildItem -Path (Join-Path $ProjectRoot "app") -Recurse -Include *.tsx -File
$changed = 0
foreach($f in $files){
  $orig = Get-Content $f.FullName -Raw -Encoding UTF8
  $t = $orig
  $t = RemoveSafeAreaFromRNImports $t
  $t = ConsolidateSafeAreaContextImports $t
  if($t -ne $orig){
    Copy-Item $f.FullName "$($f.FullName).bak.$(Get-Date -Format yyyyMMdd-HHmmss)" -Force
    Set-Content $f.FullName -Value $t -Encoding UTF8
    $changed++
    Log "Updated imports: $($f.FullName)"
  }
}
Log "Files changed: $changed"

# 3) Ensure package installed (idempotent)
Push-Location $ProjectRoot
try{
  Log "expo install react-native-safe-area-context"
  & npx expo install react-native-safe-area-context | Tee-Object -FilePath $LogPath -Append
}catch{ Log ("ERROR: " + $_.Exception.Message) }
Pop-Location

Log "== DONE =="

