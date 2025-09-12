# fm-expo-cli-repair-start-v2.ps1
$ErrorActionPreference = "Stop"

$projectRoot="D:\FundMind"
$toolsDir = Join-Path $projectRoot "tools"
$logsDir  = Join-Path $projectRoot "logs"
$antiErr  = Join-Path $logsDir "antierrors.log"
if(!(Test-Path $logsDir)){ New-Item -ItemType Directory -Force -Path $logsDir | Out-Null }

function Log([string]$m){ $t=Get-Date -Format s; Write-Host "[ExpoRepair] $m"; "$t [Info] $m" | Out-File (Join-Path $logsDir "expo-repair-start.log") -Append -Encoding UTF8 }
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

# Bezpieczne ustawianie props?w z nietypowymi nazwami (np. "@expo/cli")
function Set-JsonProp([Parameter(Mandatory=$true)]$psobj, [Parameter(Mandatory=$true)][string]$name, $value){
  $p = $psobj.PSObject.Properties | Where-Object { $_.Name -eq $name }
  if($p){ $psobj.PSObject.Properties.Remove($name) | Out-Null }
  $psobj | Add-Member -NotePropertyName $name -NotePropertyValue $value
}

function Ensure-Babel([string]$sdk){
  $babel = Join-Path $projectRoot "babel.config.js"
  if($sdk -like "49.*"){
    $c='module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["expo-router/babel","react-native-reanimated/plugin"] }; };'
    Write-Utf8NoBom $babel $c; Log "babel.config.js -> SDK49 (WITH expo-router/babel)"; return @("--lan","-c","--force-manifest-type=classic")
  } else {
    $c='module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["react-native-reanimated/plugin"] }; };'
    Write-Utf8NoBom $babel $c; Log "babel.config.js -> SDK50+ (NO expo-router/babel)"; return @("--lan","-c")
  }
}

function Harden-Env(){
  if($env:DEBUG -or $env:EXPO_DEBUG){ AE "AE-67 DEBUG_LEFTOVER_CLEARED" ("DEBUG="+$env:DEBUG+" EXPO_DEBUG="+$env:EXPO_DEBUG); Remove-Item Env:\DEBUG -ErrorAction SilentlyContinue; Remove-Item Env:\EXPO_DEBUG -ErrorAction SilentlyContinue }
  if($env:CI){ AE "AE-65 CI_LEFTOVER_CLEARED" ("CI="+$env:CI); $env:CI="" }
  $env:COMSPEC="$env:SystemRoot\System32\cmd.exe"
  $add=@("$env:SystemRoot\System32","$env:SystemRoot","$env:SystemRoot\System32\WindowsPowerShell\v1.0","$env:SystemRoot\System32\wbem","C:\Windows\System32\OpenSSH","C:\Program Files\Git\bin")
  $cur=$env:PATH -split ";"; foreach($p in $add){ if($p -and (Test-Path $p) -and -not ($cur -contains $p)){ $cur=@($p)+$cur } }; $env:PATH=($cur -join ";")
  $env:BROWSER="none"; $env:EXPO_NO_DOCTOR="1"; $env:npm_config_legacy_peer_deps="true"; $env:EXPO_NO_WSL="1"
}

function Free-Port8081(){
  $lines = cmd.exe /c "netstat -ano | findstr :8081" 2>$null
  if($lines){ AE "AE-70 PORT_8081_BUSY" ($lines -join " | "); foreach($ln in $lines){ $parts=$ln -split "\s+"; if($parts.Length -gt 0){ $pid=$parts[$parts.Length-1]; if($pid -match '^\d+$'){ try{ Stop-Process -Id [int]$pid -Force -ErrorAction SilentlyContinue } catch {} } } } }
}
function Open-Firewall8081(){
  try{ if(Get-Command New-NetFirewallRule -ErrorAction SilentlyContinue){ if(-not (Get-NetFirewallRule -DisplayName "NodeJS Dev Server 8081" -ErrorAction SilentlyContinue)){ New-NetFirewallRule -DisplayName "NodeJS Dev Server 8081" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8081 | Out-Null; Log "Firewall rule added for 8081 (AE-76)" } } } catch { AE "AE-76 FW_RULE_FAIL" $_.Exception.Message }
}

function Ensure-Expo-And-CLI([string]$sdk){
  $pkgP=Join-Path $projectRoot "package.json"; $pkg=Read-JsonSafe $pkgP
  if(-not $pkg.dependencies){ $pkg | Add-Member -Name dependencies -MemberType NoteProperty -Value (@{}) }
  if(-not $pkg.devDependencies){ $pkg | Add-Member -Name devDependencies -MemberType NoteProperty -Value (@{}) }

  $want = if($sdk -like "49.*"){ "~49.0.21" } elseif($sdk -like "50.*"){ "~50.0.0" } else { "~50.0.0" }
  if(-not ($pkg.dependencies.PSObject.Properties.Name -contains "expo") -or $pkg.dependencies.expo -notlike $want){ Set-JsonProp -psobj $pkg.dependencies -name "expo" -value $want; Log ("Pinned expo "+$want+" (AE-55)") }

  # <<< FIX: klucz z uko?nikiem dodajemy przez Add-Member >>>
  if(-not ($pkg.devDependencies.PSObject.Properties.Name -contains "@expo/cli")){
    Set-JsonProp -psobj $pkg.devDependencies -name "@expo/cli" -value "^0.17.0"
    AE "AE-82 PROP_NAME_WITH_SLASH_FIXED" "@expo/cli added via Add-Member"
  } else {
    Set-JsonProp -psobj $pkg.devDependencies -name "@expo/cli" -value "^0.17.0"
  }

  # main = expo-router/entry
  if(-not ($pkg.PSObject.Properties.Name -contains "main") -or $pkg.main -ne "expo-router/entry"){ Set-JsonProp -psobj $pkg -name "main" -value "expo-router/entry"; Log "package.json: set main=expo-router/entry" }

  Save-Json $pkgP $pkg

  $needInstall=$false
  if(!(Test-Path (Join-Path $projectRoot "node_modules\expo\bin\cli.js"))){ AE "AE-80 MISSING_EXPO_BIN" "expo/bin/cli.js not found"; $needInstall=$true }
  if(!(Test-Path (Join-Path $projectRoot "node_modules\@expo\cli\build\bin\cli.js"))){ AE "AE-81 MISSING_ATEXPO_CLI" "@expo/cli bin not found"; $needInstall=$true }
  if($needInstall){
    if(Test-Path (Join-Path $projectRoot "node_modules")){ Remove-Item -Recurse -Force (Join-Path $projectRoot "node_modules") }
    if(Test-Path (Join-Path $projectRoot "package-lock.json")){ Remove-Item -Force (Join-Path $projectRoot "package-lock.json") }
    Log "npm install --legacy-peer-deps (repair CLI)"; npm install --legacy-peer-deps
    if($LASTEXITCODE -ne 0){ AE "AE-53 NPM_INSTALL_FAILED" ("exit "+$LASTEXITCODE); throw "npm install failed ($LASTEXITCODE)" }
  }
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
  $outLog = Join-Path $logsDir ("expo-repair-start-{0}.out.log" -f $ts)
  $errLog = Join-Path $logsDir ("expo-repair-start-{0}.err.log" -f $ts)

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
    Log "Starting (.bin\expo.cmd): "+$expoCmd+" "+($all -join " ")
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

  foreach($f in @("package.json","app.json","tsconfig.json")){ if(Test-Path (Join-Path $projectRoot $f)){ try{ $tmp=Read-JsonSafe (Join-Path $projectRoot $f); Save-Json (Join-Path $projectRoot $f) $tmp } catch {} } }

  $app = Read-JsonSafe (Join-Path $projectRoot "app.json")
  $sdk = if($app.expo -and $app.expo.sdkVersion){ $app.expo.sdkVersion } else { "50.0.0" }
  $argsArr = Ensure-Babel $sdk

  Harden-Env
  Free-Port8081
  Open-Firewall8081
  Ensure-Expo-And-CLI $sdk

  if(Test-Path ".\.expo"){ Remove-Item -Recurse -Force ".\.expo" }
  if(Test-Path ".\.expo-shared"){ Remove-Item -Recurse -Force ".\.expo-shared" }

  Start-Expo $argsArr
}
catch{
  AE "AE-54 START_FAILED" $_.Exception.Message
  Write-Host ("[ExpoRepair-Error] " + $_.Exception.Message)
  exit 1
}
