# fm-start-live.ps1  (PS 5.1)
$ErrorActionPreference = "Stop"
$pr   = "D:\FundMind"
$logs = Join-Path $pr "logs"
$ae   = Join-Path $logs "antierrors.log"
function Log($m){ $t=Get-Date -Format s; Write-Host "[Live] $m"; "$t [Info] $m"|Out-File (Join-Path $logs "live-summary.log") -Append -Enc utf8 }
function AE($c,$m){ $t=Get-Date -Format s; "$t [$c] $m"|Out-File $ae -Append -Enc utf8 }
function WUtf8NoBom($p,$txt){ $enc=New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllText($p,$txt,$enc) }
function ReadJson($p){
  if(!(Test-Path $p)){ throw "$p not found" }
  $b=[IO.File]::ReadAllBytes($p)
  if($b.Length -ge 3 -and $b[0]-eq 239 -and $b[1]-eq 187 -and $b[2]-eq 191){ AE "AE-56 JSON_BOM_REWRITE" ("BOM in "+(Split-Path $p -Leaf)); $b=$b[3..($b.Length-1)]; [IO.File]::WriteAllBytes($p,$b) }
  $t=[Text.Encoding]::UTF8.GetString($b)
  try{ return ($t|ConvertFrom-Json) } catch { AE "AE-49-JSON" ("invalid "+(Split-Path $p -Leaf)+": "+$_.Exception.Message); throw }
}
function SaveJson($p,$o){ $j=$o|ConvertTo-Json -Depth 40; WUtf8NoBom $p $j }

try{
  Set-Location $pr
  # 0) Środowisko – żywy start, brak CI
  if($env:CI){ AE "AE-65 CI_LEFTOVER_CLEARED" $env:CI; Remove-Item Env:CI -ErrorAction SilentlyContinue }
  $env:COMSPEC = "$env:SystemRoot\System32\cmd.exe"
  foreach($add in @("$env:SystemRoot","$env:SystemRoot\System32","$env:SystemRoot\System32\WindowsPowerShell\v1.0","C:\Program Files\Git\bin")){
    if($add -and (Test-Path $add) -and -not (($env:PATH -split ";") -contains $add)){ $env:PATH = $add + ";" + $env:PATH }
  }

  # 1) Metro config – zero deep importów
  $metro = 'const { getDefaultConfig } = require("expo/metro-config"); const config = getDefaultConfig(__dirname); module.exports = config;'
  WUtf8NoBom (Join-Path $pr "metro.config.js") $metro
  Log "metro.config.js reset"

  # 2) JSON sanity + main
  foreach($f in @("package.json","app.json","tsconfig.json")){ if(Test-Path (Join-Path $pr $f)){ try{ $x=ReadJson (Join-Path $pr $f); SaveJson (Join-Path $pr $f) $x } catch{} } }
  $app = ReadJson (Join-Path $pr "app.json")
  $sdk = if($app.expo -and $app.expo.sdkVersion){ $app.expo.sdkVersion } else { "50.0.0" }

  $pkgP = Join-Path $pr "package.json"
  $pkg  = ReadJson $pkgP
  if(-not $pkg.dependencies){ $pkg | Add-Member -Name dependencies -MemberType NoteProperty -Value (@{}) }
  if(-not ($pkg.PSObject.Properties.Name -contains "main") -or $pkg.main -ne "expo-router/entry"){ $pkg.main="expo-router/entry"; SaveJson $pkgP $pkg; Log "package.json main=expo-router/entry" }

  # 3) babel pod SDK
  if($sdk -like "49.*"){
    $babel='module.exports=function(api){api.cache(true);return{presets:["babel-preset-expo"],plugins:["expo-router/babel","react-native-reanimated/plugin"]};};'
    $args=@("--tunnel","-c","--force-manifest-type=classic")
    Log "babel -> SDK49"
  } else {
    $babel='module.exports=function(api){api.cache(true);return{presets:["babel-preset-expo"],plugins:["react-native-reanimated/plugin"]};};'
    $args=@("--tunnel","-c")
    Log "babel -> SDK50+"
  }
  WUtf8NoBom (Join-Path $pr "babel.config.js") $babel

  # 4) Expo lokalnie (jeśli brak – doinstaluj)
  $wantExpo = if($sdk -like "49.*"){ "~49.0.21" } else { "~50.0.0" }
  if(-not ($pkg.dependencies.PSObject.Properties.Name -contains "expo") -or $pkg.dependencies.expo -notlike $wantExpo){
    $pkg.dependencies.expo = $wantExpo; SaveJson $pkgP $pkg; Log ("pin expo "+$wantExpo+" (AE-55)")
  }
  if(!(Test-Path (Join-Path $pr "node_modules\expo"))){
    if(Test-Path (Join-Path $pr "node_modules")){ Remove-Item -Recurse -Force (Join-Path $pr "node_modules") }
    if(Test-Path (Join-Path $pr "package-lock.json")){ Remove-Item -Force (Join-Path $pr "package-lock.json") }
    Log "npm install --legacy-peer-deps"
    npm install --legacy-peer-deps
    if($LASTEXITCODE -ne 0){ AE "AE-53 NPM_INSTALL_FAILED" ("exit "+$LASTEXITCODE); throw "npm install failed ($LASTEXITCODE)" }
  }

  # 5) Czyść cache projektu i zwolnij port 8081
  if(Test-Path ".\.expo"){ Remove-Item -Recurse -Force ".\.expo" }
  if(Test-Path ".\.expo-shared"){ Remove-Item -Recurse -Force ".\.expo-shared" }
  $busy = cmd.exe /c "netstat -ano | findstr :8081" 2>$null
  if($busy){ AE "AE-70 PORT_8081_BUSY" ($busy -join " | "); foreach($ln in $busy){ $s=$ln -split "\s+"; $pid=$s[$s.Length-1]; if($pid -match '^\d+$'){ try{ Stop-Process -Id ([int]$pid) -Force -ErrorAction SilentlyContinue }catch{} } } }

  # 6) Wybór CLI i START NA PIERWSZYM PLANIE (konsola żyje, QR na ekranie)
  $cli1 = Join-Path $pr "node_modules\expo\bin\cli.js"
  $cli2 = Join-Path $pr "node_modules\@expo\cli\build\bin\cli.js"
  $expoCmd = Join-Path $pr "node_modules\.bin\expo.cmd"
  if(Test-Path $cli1){
    Log ("run: node "+$cli1+" start "+($args -join " "))
    & node $cli1 start @args   # <-- Zostaje w tej samej konsoli, pokazuje QR
  } elseif (Test-Path $cli2){
    Log ("run: node "+$cli2+" start "+($args -join " "))
    & node $cli2 start @args
  } elseif (Test-Path $expoCmd){
    Log ("run: "+$expoCmd+" start "+($args -join " "))
    & $expoCmd start @args
  } else {
    AE "AE-52 CLI_NOT_FOUND" "fallback to npx"
    Log ("run: npx expo start "+($args -join " "))
    & npx expo start @args
  }
}
catch{
  AE "AE-54 START_FAILED" $_.Exception.Message
  Write-Host ("[Live-Error] "+$_.Exception.Message)
  exit 1
}