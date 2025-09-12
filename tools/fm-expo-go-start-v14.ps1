# fm-expo-go-start-v14.ps1
$ErrorActionPreference = "Stop"

$projectRoot="D:\FundMind"
$toolsDir = Join-Path $projectRoot "tools"
$logsDir  = Join-Path $projectRoot "logs"
$antiErr  = Join-Path $logsDir "antierrors.log"
if(!(Test-Path $logsDir)){ New-Item -ItemType Directory -Force -Path $logsDir | Out-Null }

function Log([string]$m){ $t=Get-Date -Format s; Write-Host "[ExpoGoStart] $m"; "$t [Info] $m" | Out-File (Join-Path $logsDir "expo-start-summary.log") -Append -Encoding UTF8 }
function AE([string]$code,[string]$msg){ $t=Get-Date -Format s; "$t [$code] $msg" | Out-File $antiErr -Append -Encoding UTF8 }
function Write-Utf8NoBom([string]$path,[string]$text){ $enc = New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllText($path,$text,$enc) }
function Read-JsonSafe([string]$path){
  if(!(Test-Path $path)){ throw "$path not found" }
  $b=[IO.File]::ReadAllBytes($path)
  if($b.Length -ge 3 -and $b[0]-eq 239 -and $b[1]-eq 187 -and $b[2]-eq 191){
    AE "AE-56 JSON_BOM_REWRITE" ("BOM in " + (Split-Path $path -Leaf))
    $b=$b[3..($b.Length-1)]; [IO.File]::WriteAllBytes($path,$b)
  }
  $t=[Text.Encoding]::UTF8.GetString($b)
  try{ return ($t|ConvertFrom-Json) } catch { AE "AE-49-JSON" ("invalid JSON " + (Split-Path $path -Leaf) + ": " + $_.Exception.Message); throw }
}
function Save-Json([string]$path,$obj){ $json=$obj|ConvertTo-Json -Depth 50; Write-Utf8NoBom $path $json }

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

function Ensure-Expo([string]$sdk){
  $pkgP=Join-Path $projectRoot "package.json"; $pkg=Read-JsonSafe $pkgP
  if(-not $pkg.dependencies){ $pkg | Add-Member -Name dependencies -MemberType NoteProperty -Value (@{}) }
  $want = if($sdk -like "49.*"){ "~49.0.21" } elseif($sdk -like "50.*"){ "~50.0.0" } else { "~50.0.0" }
  if(-not ($pkg.dependencies.PSObject.Properties.Name -contains "expo") -or $pkg.dependencies.expo -notlike $want){
    $pkg.dependencies.expo=$want; Save-Json $pkgP $pkg; Log ("Pinned expo "+$want+" (AE-55)")
  }
  $expoDir=Join-Path $projectRoot "node_modules\expo"
  if(!(Test-Path $expoDir)){
    if(Test-Path (Join-Path $projectRoot "node_modules")){ Remove-Item -Recurse -Force (Join-Path $projectRoot "node_modules") }
    if(Test-Path (Join-Path $projectRoot "package-lock.json")){ Remove-Item -Force (Join-Path $projectRoot "package-lock.json") }
    Log "npm install --legacy-peer-deps"; npm install --legacy-peer-deps
    if($LASTEXITCODE -ne 0){ AE "AE-53 NPM_INSTALL_FAILED" ("exit "+$LASTEXITCODE); throw "npm install failed ($LASTEXITCODE)" }
  }
}

function Harden-Env(){
  $global:LASTEXITCODE=0
  if($env:DEBUG -or $env:EXPO_DEBUG){ AE "AE-67 DEBUG_LEFTOVER_CLEARED" ("DEBUG="+$env:DEBUG+" EXPO_DEBUG="+$env:EXPO_DEBUG); Remove-Item Env:\DEBUG -ErrorAction SilentlyContinue; Remove-Item Env:\EXPO_DEBUG -ErrorAction SilentlyContinue }
  if($env:CI){ AE "AE-65 CI_LEFTOVER_CLEARED" ("CI="+$env:CI); $env:CI="" }
  $env:COMSPEC="$env:SystemRoot\System32\cmd.exe"
  $add=@("$env:SystemRoot\System32","$env:SystemRoot","$env:SystemRoot\System32\WindowsPowerShell\v1.0","$env:SystemRoot\System32\wbem","C:\Windows\System32\OpenSSH","C:\Program Files\Git\bin")
  $cur=$env:PATH -split ";"; foreach($p in $add){ if($p -and (Test-Path $p) -and -not ($cur -contains $p)){ $cur=@($p)+$cur } }; $env:PATH=($cur -join ";")
  $env:BROWSER="none"; $env:EXPO_NO_DOCTOR="1"; $env:npm_config_legacy_peer_deps="true"; $env:EXPO_NO_WSL="1"
}

function Ensure-Shims(){
  $shim=Join-Path $toolsDir "shims"; if(!(Test-Path $shim)){ New-Item -ItemType Directory -Force -Path $shim | Out-Null }
  $adb=Join-Path $shim "adb.cmd"; if(!(Test-Path $adb)){ @(":: AE-61 SHIM_ADB","@echo off","echo [shim] adb %*","exit /b 0") | Set-Content -Path $adb -Encoding ASCII }
  if(-not ($env:PATH -split ";" | Where-Object { $_ -ieq $shim })){ $env:PATH = ($shim + ";" + $env:PATH) }
  Log "Shim dir on PATH"
}

function Find-ExpoCLI(){
  $root = Join-Path $projectRoot "node_modules\expo"; if(!(Test-Path $root)){ return $null }
  $cand = Get-ChildItem -Path $root -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Name -match "^cli\.(c?js)$" -and $_.FullName -like "*\bin\*" } | Select-Object -First 1
  if($cand){ return $cand.FullName } return $null
}

function Free-Port8081(){
  $lines = cmd.exe /c "netstat -ano | findstr :8081" 2>$null
  if($lines){ AE "AE-70 PORT_8081_BUSY" ($lines -join " | "); foreach($ln in $lines){ $parts=$ln -split "\s+"; if($parts.Length -gt 0){ $pid=$parts[$parts.Length-1]; if($pid -match '^\d+$'){ try{ Stop-Process -Id [int]$pid -Force -ErrorAction SilentlyContinue } catch {} } } } }
}

function Open-Firewall8081(){
  try{
    if(Get-Command New-NetFirewallRule -ErrorAction SilentlyContinue){
      $rule = Get-NetFirewallRule -DisplayName "NodeJS Dev Server 8081" -ErrorAction SilentlyContinue
      if(-not $rule){ New-NetFirewallRule -DisplayName "NodeJS Dev Server 8081" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 8081 | Out-Null; Log "Firewall rule added for 8081 (AE-76)" }
    }
  } catch { AE "AE-76 FW_RULE_FAIL" $_.Exception.Message }
}

try{
  Set-Location $projectRoot

  foreach($f in @("package.json","app.json","tsconfig.json")){ $p=Join-Path $projectRoot $f; if(Test-Path $p){ try{ $tmp=Read-JsonSafe $p; Save-Json $p $tmp } catch {} } }
  $app = Read-JsonSafe (Join-Path $projectRoot "app.json")
  $sdk = if($app.expo -and $app.expo.sdkVersion){ $app.expo.sdkVersion } else { "49.0.0" }
  $argsArr = Ensure-Babel $sdk

  $pkgP = Join-Path $projectRoot "package.json"
  if(Test-Path $pkgP){ $pkg=Read-JsonSafe $pkgP; if(-not ($pkg.PSObject.Properties.Name -contains "main") -or $pkg.main -ne "expo-router/entry"){ $pkg.main="expo-router/entry"; Save-Json $pkgP $pkg; Log "package.json: set main=expo-router/entry" } }

  Harden-Env
  Ensure-Expo $sdk
  Ensure-Shims
  Free-Port8081
  Open-Firewall8081

  if(Test-Path ".\.expo"){ Remove-Item -Recurse -Force ".\.expo" }
  if(Test-Path ".\.expo-shared"){ Remove-Item -Recurse -Force ".\.expo-shared" }

  $cliJs  = Find-ExpoCLI
  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
  $outLog = Join-Path $logsDir ("expo-start-{0}.out.log" -f $ts)
  $errLog = Join-Path $logsDir ("expo-start-{0}.err.log" -f $ts)
  $meta   = Join-Path $logsDir ("expo-start-{0}.meta.txt" -f $ts)

  "=== ENV SNAPSHOT ===" | Out-File $meta -Encoding UTF8
  foreach($n in @("node","npm","git","cmd","powershell")){ try{ $p=(Get-Command $n -ErrorAction SilentlyContinue).Source; ("FOUND {0}: {1}" -f $n,$p) | Out-File $meta -Append } catch { ("MISS {0}" -f $n) | Out-File $meta -Append } }
  ("PATH="+$env:PATH) | Out-File $meta -Append
  ("SDK="+$sdk)       | Out-File $meta -Append
  "" | Out-File $meta -Append

  if(!$cliJs){ AE "AE-52 CLI_NOT_FOUND" "expo cli.js not found after install"; throw "CLI not found (node_modules\expo\bin\cli.js)" }

  # Start w OSOBNYM OKNIE, bez przechwytywania STDOUT do bie??cej konsoli
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.WorkingDirectory = $projectRoot
  $psi.FileName = (Get-Command node).Source
  $allArgs = @($cliJs,"start") + $argsArr
  $psi.ArgumentList.AddRange($allArgs)
  AE "AE-59 SPAWN_TARGET" ("node "+($allArgs -join " "))
  Log ("Spawning Metro in new window...")
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError  = $true
  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = $psi
  $null = $p.Start()
  $p.BeginOutputReadLine(); $p.BeginErrorReadLine()
  $p.OutputDataReceived += { if($_.Data){ $_.Data | Out-File $outLog -Append -Encoding UTF8 } }
  $p.ErrorDataReceived  += { if($_.Data){ $_.Data | Out-File $errLog -Append -Encoding UTF8 } }

  Log ("Metro started. OUT: "+$outLog+"  ERR: "+$errLog)
  Log ("W Expo Go wybierz Scan QR (tryb LAN). Je?li nie widzisz QR, wejd? na http://localhost:8081/debug.")

} catch {
  AE "AE-54 START_FAILED" $_.Exception.Message
  Write-Host ("[ExpoGoStart-Error] " + $_.Exception.Message)
  exit 1
}
