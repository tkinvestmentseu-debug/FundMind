# fm-fix-metro-and-start.ps1
$ErrorActionPreference = "Stop"

$projectRoot="D:\FundMind"
$logsDir  = Join-Path $projectRoot "logs"
$antiErr  = Join-Path $logsDir "antierrors.log"
if(!(Test-Path $logsDir)){ New-Item -ItemType Directory -Force -Path $logsDir | Out-Null }

function Log([string]$m){ $t=Get-Date -Format s; Write-Host "[MetroFix] $m"; "$t [Info] $m" | Out-File (Join-Path $logsDir "metro-fix-summary.log") -Append -Encoding UTF8 }
function AE([string]$code,[string]$msg){ $t=Get-Date -Format s; "$t [$code] $msg" | Out-File $antiErr -Append -Encoding UTF8 }

function Write-Utf8NoBom([string]$path,[string]$text){ $enc=New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllText($path,$text,$enc) }
function Read-JsonSafe([string]$path){
  if(!(Test-Path $path)){ throw "$path not found" }
  $b=[IO.File]::ReadAllBytes($path)
  if($b.Length -ge 3 -and $b[0]-eq 239 -and $b[1]-eq 187 -and $b[2]-eq 191){ AE "AE-56 JSON_BOM_REWRITE" ("BOM in "+(Split-Path $path -Leaf)); $b=$b[3..($b.Length-1)]; [IO.File]::WriteAllBytes($path,$b) }
  $t=[Text.Encoding]::UTF8.GetString($b)
  try{ return ($t|ConvertFrom-Json) } catch { AE "AE-49-JSON" ("invalid JSON "+(Split-Path $path -Leaf)+": "+$_.Exception.Message); throw }
}
function Save-Json([string]$path,$obj){ $json=$obj|ConvertTo-Json -Depth 50; Write-Utf8NoBom $path $json }
function Set-JsonProp($psobj,[string]$name,$value){ $p=$psobj.PSObject.Properties | Where-Object { $_.Name -eq $name }; if($p){ $psobj.PSObject.Properties.Remove($name) | Out-Null }; $psobj | Add-Member -NotePropertyName $name -NotePropertyValue $value }

function Harden-Env(){
  # Czy?? ?lewe? flagi, w??cz potrzebne ?cie?ki
  if($env:DEBUG -or $env:EXPO_DEBUG){ AE "AE-67 DEBUG_LEFTOVER_CLEARED" ("DEBUG="+$env:DEBUG+" EXPO_DEBUG="+$env:EXPO_DEBUG); Remove-Item Env:\DEBUG -ErrorAction SilentlyContinue; Remove-Item Env:\EXPO_DEBUG -ErrorAction SilentlyContinue }
  if($env:CI){ AE "AE-65 CI_LEFTOVER_CLEARED" ("CI="+$env:CI); $env:CI="" }
  $env:COMSPEC="$env:SystemRoot\System32\cmd.exe"
  $add=@("$env:SystemRoot\System32","$env:SystemRoot","$env:SystemRoot\System32\WindowsPowerShell\v1.0","$env:SystemRoot\System32\wbem","C:\Windows\System32\OpenSSH","C:\Program Files\Git\bin")
  $cur=$env:PATH -split ";"; foreach($p in $add){ if($p -and (Test-Path $p) -and -not ($cur -contains $p)){ $cur=@($p)+$cur } }; $env:PATH=($cur -join ";")
  $env:BROWSER="none"; $env:EXPO_NO_DOCTOR="1"; $env:npm_config_legacy_peer_deps="true"; $env:EXPO_NO_WSL="1"
}

function Ensure-Babel([string]$sdk){
  $babel = Join-Path $projectRoot "babel.config.js"
  if($sdk -like "49.*"){
    $c='module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["expo-router/babel","react-native-reanimated/plugin"] }; };'
    Write-Utf8NoBom $babel $c; Log "babel.config.js -> SDK49"
    return @("--tunnel","-c","--force-manifest-type=classic")
  } else {
    $c='module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["react-native-reanimated/plugin"] }; };'
    Write-Utf8NoBom $babel $c; Log "babel.config.js -> SDK50+"
    return @("--tunnel","-c")
  }
}

function Free-Port8081(){
  $lines = cmd.exe /c "netstat -ano | findstr :8081" 2>$null
  if($lines){ AE "AE-70 PORT_8081_BUSY" ($lines -join " | "); foreach($ln in $lines){ $parts=$ln -split "\s+"; if($parts.Length -gt 0){ $pid=$parts[$parts.Length-1]; if($pid -match '^\d+$'){ try{ Stop-Process -Id [int]$pid -Force -ErrorAction SilentlyContinue } catch {} } } } }
}
function Open-Firewall8081(){
  try{ if(Get-Command New-NetFirewallRule -ErrorAction SilentlyContinue){ if(-not (Get-NetFirewallRule -DisplayName "NodeJS Dev Server 8081" -ErrorAction SilentlyContinue)){ New-NetFirewallRule -DisplayName "NodeJS Dev Server 8081" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8081 | Out-Null; Log "Firewall rule added for 8081" } } } catch { AE "AE-76 FW_RULE_FAIL" $_.Exception.Message }
}

function Ensure-MetroDeps([string]$sdk,[string]$rn){
  Log "Ensuring Metro deps (SDK $sdk, RN $rn)"
  # 1) spr?buj dopasowane wersje przez expo install
  $expoInstall = { param($pkgs) & npx expo install @pkgs }
  try{
    & npx expo install @react-native/metro-config metro metro-cache metro-config metro-resolver 2>&1 | Tee-Object -FilePath (Join-Path $logsDir "metro-expo-install.log")
    if($LASTEXITCODE -eq 0){ Log "expo install metro* OK"; return }
    AE "AE-91 EXPO_INSTALL_FAILED" ("expo install exit "+$LASTEXITCODE)
  } catch {
    AE "AE-91 EXPO_INSTALL_FAILED" $_.Exception.Message
  }

  # 2) awaryjne piny wersji Metro (heurystyka po RN)
  $base = "0.80.9"
  if($rn -like "0.72*"){ $base = "0.76.8" }
  elseif($rn -like "0.73*"){ $base = "0.80.9" }
  AE "AE-90 METRO_MISSING" ("forcing metro base "+$base)
  Log "npm i -D metro@$base metro-cache@$base metro-config@$base metro-resolver@$base @react-native/metro-config@latest"
  npm i -D metro@$base metro-cache@$base metro-config@$base metro-resolver@$base @react-native/metro-config@latest --legacy-peer-deps
  if($LASTEXITCODE -ne 0){ AE "AE-53 NPM_INSTALL_FAILED" ("exit "+$LASTEXITCODE); throw "metro fallback install failed ($LASTEXITCODE)" }

  Log "npm dedupe"
  npm dedupe
}

function Find-ExpoCLI(){
  $cli1 = Join-Path $projectRoot "node_modules\expo\bin\cli.js"
  $cli2 = Join-Path $projectRoot "node_modules\@expo\cli\build\bin\cli.js"
  if(Test-Path $cli1){ return $cli1 }
  if(Test-Path $cli2){ return $cli2 }
  return $null
}

function Start-Expo([string[]]$argsArr){
  $cli = Find-ExpoCLI
  $expoCmd = Join-Path $projectRoot "node_modules\.bin\expo.cmd"
  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
  $outLog = Join-Path $logsDir ("metro-fix-start-{0}.out.log" -f $ts)
  $errLog = Join-Path $logsDir ("metro-fix-start-{0}.err.log" -f $ts)

  "=== ENV ===" | Out-File $outLog -Encoding UTF8
  foreach($n in @("node","npm","git","cmd","powershell")){ try{ $p=(Get-Command $n -ErrorAction SilentlyContinue).Source; ("FOUND {0}: {1}" -f $n,$p) | Out-File $outLog -Append } catch { } }
  ("PATH="+$env:PATH) | Out-File $outLog -Append
  "" | Out-File $outLog -Append

  if($cli){
    $all=@($cli,"start") + $argsArr
    AE "AE-59 SPAWN_TARGET" ("node "+($all -join " "))
    Log "Starting (node cli): node "+($all -join " ")
    & node $all 2> $errLog | Tee-Object -FilePath $outLog
    return
  }
  if(Test-Path $expoCmd){
    $all=@("start") + $argsArr
    AE "AE-59 SPAWN_TARGET" ($expoCmd+" "+($all -join " "))
    Log "Starting (.bin\expo): "+$expoCmd+" "+($all -join " ")
    & $expoCmd $all 2> $errLog | Tee-Object -FilePath $outLog
    return
  }
  AE "AE-52 CLI_NOT_FOUND" "fallback to npx expo"
  $all=@("expo","start") + $argsArr
  Log "Starting (npx): npx "+($all -join " ")
  & npx $all 2> $errLog | Tee-Object -FilePath $outLog
}

try{
  Set-Location $projectRoot

  # sanity JSON + odczyt wersji
  foreach($f in @("package.json","app.json","tsconfig.json")){ if(Test-Path (Join-Path $projectRoot $f)){ try{ $tmp=Read-JsonSafe (Join-Path $projectRoot $f); Save-Json (Join-Path $projectRoot $f) $tmp } catch {} } }
  $app = Read-JsonSafe (Join-Path $projectRoot "app.json")
  $pkg = Read-JsonSafe (Join-Path $projectRoot "package.json")
  $sdk = if($app.expo -and $app.expo.sdkVersion){ $app.expo.sdkVersion } else { "50.0.0" }
  $rn  = if($pkg.dependencies."react-native"){ $pkg.dependencies."react-native" } else { "" }

  # main = expo-router/entry (dla routera)
  if(-not ($pkg.PSObject.Properties.Name -contains "main") -or $pkg.main -ne "expo-router/entry"){ Set-JsonProp -psobj $pkg -name "main" -value "expo-router/entry"; Save-Json (Join-Path $projectRoot "package.json") $pkg; Log "package.json: set main=expo-router/entry" }

  $argsArr = Ensure-Babel $sdk
  Harden-Env
  Free-Port8081
  Open-Firewall8081

  # najpierw sprz?tanie cache Expo
  if(Test-Path ".\.expo"){ Remove-Item -Recurse -Force ".\.expo" }
  if(Test-Path ".\.expo-shared"){ Remove-Item -Recurse -Force ".\.expo-shared" }

  # kluczowe: doinstaluj brakuj?ce metro*
  Ensure-MetroDeps $sdk $rn

  # start
  Start-Expo $argsArr
}
catch{
  AE "AE-54 START_FAILED" $_.Exception.Message
  Write-Host ("[MetroFix-Error] " + $_.Exception.Message)
  exit 1
}
