param([string]$ProjectRoot,[string]$LogPath)
function Write-Log($m){$l="[ $(Get-Date -Format HH:mm:ss) ] $m";$l|Out-File -FilePath $LogPath -Append -Encoding UTF8;Write-Host $l}

Write-Log "== START =="
$tx = Join-Path $ProjectRoot "app\_data\transactions.ts"
if(Test-Path $tx){
  $bak="$tx.bak.$(Get-Date -Format yyyyMMdd-HHmmss)"
  Copy-Item $tx $bak -Force
  $c=Get-Content $tx -Raw -Encoding UTF8
  if($c -notmatch "export\s+default\s+") {
    $add="`r`n/** auto-added to satisfy expo-router */`r`nexport default function DataRoutePlaceholder(){return null;}"
    Set-Content $tx -Value ($c+$add) -Encoding UTF8
    Write-Log "Added default export to _data/transactions.ts"
  } else { Write-Log "Default export already present." }
}else{ Write-Log "File not found: $tx" }

$tsx=Get-ChildItem -Path (Join-Path $ProjectRoot app) -Recurse -Include *.tsx
$cnt=0
foreach($f in $tsx){
  $t=Get-Content $f.FullName -Raw -Encoding UTF8
  $o=$t
  $t=[regex]::Replace($t,"import\s*\{\s*SafeAreaView\s*\}\s*from\s*'react-native';?","import { SafeAreaView } from 'react-native-safe-area-context';",[Text.RegularExpressions.RegexOptions]::IgnoreCase)
  if($t -ne $o){
    Copy-Item $f.FullName "$($f.FullName).bak.$ts" -Force
    Set-Content $f.FullName -Value $t -Encoding UTF8
    $cnt++
    Write-Log "Fixed: $($f.FullName)"
  }
}
Write-Log "Updated files: $cnt"
Write-Log "Installing react-native-safe-area-context..."
Push-Location $ProjectRoot
try{ & npx expo install react-native-safe-area-context | Tee-Object -FilePath $LogPath -Append }catch{Write-Log $_}
Pop-Location
Write-Log "== DONE =="
