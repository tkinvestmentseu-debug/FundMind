# fm-expo-go-start-v11.ps1
$ErrorActionPreference = "Stop"

# --- paths ---
$tryRoots=@("D:\FundMind","D:\fundmind",(Get-Location).Path)
$projectRoot=$null; foreach($p in $tryRoots){ if(Test-Path $p){ $projectRoot=(Resolve-Path $p).Path; break } }
if(-not $projectRoot){ $projectRoot=(Get-Location).Path }
$toolsDir = Join-Path $projectRoot "tools"
$logsDir  = Join-Path $projectRoot "logs"
$antiErr  = Join-Path $logsDir "antierrors.log"
if(!(Test-Path $logsDir)){ New-Item -ItemType Directory -Force -Path $logsDir | Out-Null }

function Log([string]$m){
  $t=Get-Date -Format s
  Write-Host "[ExpoGoStart] $m"
  "$t [Info] $m" | Out-File (Join-Path $logsDir "expo-start-summary.log") -Append -Encoding UTF8
}
function AE([string]$code,[string]$msg){
  $t=Get-Date -Format s
  "$t [$code] $msg" | Out-File $antiErr -Append -Encoding UTF8
}
function Write-Utf8NoBom([string]$path,[string]$text){
  $enc = New-Object System.Text.UTF8Encoding($false)
  [IO.File]::WriteAllText($path,$text,$enc)
}
function Read-JsonSafe([string]$path){
  if(!(Test-Path $path)){ throw "$path not found" }
  $b=[IO.File]::ReadAllBytes($path)
  if($b.Length -ge 3 -and $b[0]-eq 239 -and $b[1]-eq 187 -and $b[2]-eq 191){
    AE "AE-56 JSON_BOM_REWRITE" ("BOM in " + (Split-Path $path -Leaf))
    $b=$b[3..($b.Length-1)]
    [IO.File]::WriteAllBytes($path,$b)
  }
  $t=[Text.Encoding]::UTF8.GetString($b)
  try { return ($t | ConvertFrom-Json) }
  catch { AE "AE-49-JSON" ("invalid JSON " + (Split-Path $path -Leaf) + ": " + $_.Exception.Message); throw }
}
function Save-Json([string]$path,$obj){
  $json = $obj | ConvertTo-Json -Depth 50
  Write-Utf8NoBom $path $json
}

# AE-50: poprawny babel dla SDK
function Ensure-Babel([string]$sdk){
  $babel = Join-Path $projectRoot "babel.config.js"
  if($sdk -like "49.*"){
    $c = 'module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["expo-router/babel","react-native-reanimated/plugin"] }; };'
    Write-Utf8NoBom $babel $c
    Log "babel.config.js -> SDK49 (WITH expo-router/babel)"
    return @("--tunnel","-c","--force-manifest-type=classic")
  } else {
    $c = 'module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["react-native-reanimated/plugin"] }; };'
    Write-Utf8NoBom $babel $c
    Log "babel.config.js -> SDK50+ (NO expo-router/babel)"
    return @("--tunnel","-c")
  }
}

# AE-55/53: expo w deps + instalacja gdy brak node_modules\expo
function Ensure-Expo([string]$sdk){
  $pkgP = Join-Path $projectRoot "package.json"
  $pkg  = Read-JsonSafe $pkgP
  if(-not $pkg.dependencies){ $pkg | Add-Member -Name dependencies -MemberType NoteProperty -Value (@{}) }
  $want = if($sdk -like "49.*"){ "~49.0.21" } elseif($sdk -like "50.*"){ "~50.0.0" } else { "~50.0.0" }
  if(-not ($pkg.dependencies.PSObject.Properties.Name -contains "expo") -or $pkg.dependencies.expo -notlike $want){
    $pkg.dependencies.expo = $want
    Save-Json $pkgP $pkg
    Log ("Pinned expo "+$want+" (AE-55)")
  }
  $expoDir = Join-Path $projectRoot "node_modules\expo"
  if(!(Test-Path $expoDir)){
    if(Test-Path (Join-Path $projectRoot "node_modules")){ Remove-Item -Recurse -Force (Join-Path $projectRoot "node_modules") }
    if(Test-Path (Join-Path $projectRoot "package-lock.json")){ Remove-Item -Force (Join-Path $projectRoot "package-lock.json") }
    Log "npm install --legacy-peer-deps"
    npm install --legacy-peer-deps
    if($LASTEXITCODE -ne 0){ AE "AE-53 NPM_INSTALL_FAILED" ("exit "+$LASTEXITCODE); throw "npm install failed ($LASTEXITCODE)" }
  }
}

# AE-63 PATH hardening + AE-65/AE-67 czyszczenie env
function Harden-Env(){
  $global:LASTEXITCODE=0
  if($env:DEBUG -or $env:EXPO_DEBUG){ AE "AE-67 DEBUG_LEFTOVER_CLEARED" ("DEBUG="+$env:DEBUG+" EXPO_DEBUG="+$env:EXPO_DEBUG); Remove-Item Env:\DEBUG -ErrorAction SilentlyContinue; Remove-Item Env:\EXPO_DEBUG -ErrorAction SilentlyContinue }
  if($env:CI){ AE "AE-65 CI_LEFTOVER_CLEARED" ("CI="+$env:CI); $env:CI="" }
  $env:COMSPEC = "$env:SystemRoot\System32\cmd.exe"
  $add = @(
    "$env:SystemRoot\System32","$env:SystemRoot",
    "$env:SystemRoot\System32\WindowsPowerShell\v1.0",
    "$env:SystemRoot\System32\wbem","C:\Windows\System32\OpenSSH",
    "C:\Program Files\Git\bin"
  )
  $cur = $env:PATH -split ";"
  foreach($p in $add){ if($p -and (Test-Path $p) -and -not ($cur -contains $p)){ $cur = @($p) + $cur } }
  $env:PATH = ($cur -join ";")
  $env:BROWSER="none"; $env:EXPO_NO_DOCTOR="1"; $env:npm_config_legacy_peer_deps="true"
  $env:EXPO_NO_WSL = if(Get-Command wsl.exe -ErrorAction SilentlyContinue){ "" } else { "1" }
}

# AE-61: shimy
function Ensure-Shims(){
  $shim=Join-Path $toolsDir "shims"
  if(!(Test-Path $shim)){ New-Item -ItemType Directory -Force -Path $shim | Out-Null }
  $adb=Join-Path $shim "adb.cmd"
  if(!(Test-Path $adb)){ @(":: AE-61 SHIM_ADB","@echo off","echo [shim] adb %*","exit /b 0") | Set-Content -Path $adb -Encoding ASCII }
  if(-not ($env:PATH -split ";" | Where-Object { $_ -ieq $shim })){ $env:PATH = ($shim + ";" + $env:PATH) }
  Log "Shim dir on PATH"
}

# AE-62: znajd? lokalny CLI
function Find-ExpoCLI(){
  $root = Join-Path $projectRoot "node_modules\expo"
  if(!(Test-Path $root)){ return $null }
  $cand = Get-ChildItem -Path $root -Recurse -ErrorAction SilentlyContinue `
    | Where-Object { $_.Name -match "^cli\.(c?js)$" -and $_.FullName -like "*\bin\*" } `
    | Select-Object -First 1
  if($cand){ return $cand.FullName }
  return $null
}

# AE-70: zwolnij port 8081 je?li zaj?ty
function Free-Port8081(){
  $lines = cmd.exe /c "netstat -ano | findstr :8081" 2>$null
  if($lines){
    AE "AE-70 PORT_8081_BUSY" ($lines -join " | ")
    foreach($ln in $lines){
      $parts = $ln -split "\s+"
      if($parts.Length -gt 0){ $pid = $parts[$parts.Length-1]; if($pid -match '^\d+$'){ try{ Stop-Process -Id [int]$pid -Force -ErrorAction SilentlyContinue } catch {} } }
    }
  }
}

try{
  Set-Location $projectRoot

  # JSON sanity + main
  foreach($f in @("package.json","app.json","tsconfig.json")){
    $p = Join-Path $projectRoot $f
    if(Test-Path $p){ try{ $tmp=Read-JsonSafe $p; Save-Json $p $tmp } catch {} }
  }
  $app = Read-JsonSafe (Join-Path $projectRoot "app.json")
  $sdk = if($app.expo -and $app.expo.sdkVersion){ $app.expo.sdkVersion } else { "49.0.0" }
  $argsArr = Ensure-Babel $sdk

  $pkgP = Join-Path $projectRoot "package.json"
  if(Test-Path $pkgP){
    $pkg=Read-JsonSafe $pkgP
    if(-not ($pkg.PSObject.Properties.Name -contains "main") -or $pkg.main -ne "expo-router/entry"){
      $pkg.main="expo-router/entry"; Save-Json $pkgP $pkg; Log "package.json: set main=expo-router/entry"
    }
  }

  Harden-Env
  Ensure-Expo $sdk
  Ensure-Shims
  Free-Port8081

  if(Test-Path ".\.expo"){ Remove-Item -Recurse -Force ".\.expo" }
  if(Test-Path ".\.expo-shared"){ Remove-Item -Recurse -Force ".\.expo-shared" }

  # Start w NOWYM OKNIE PS + jednoczesny zapis do logu
  $cliJs  = Find-ExpoCLI
  $expoCmd= Join-Path $projectRoot "node_modules\.bin\expo.cmd"
  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
  $startLog = Join-Path $logsDir ("expo-start-{0}.log" -f $ts)
  $argsStr = ($argsArr -join " ")

  if($cliJs){
    $exec = "node `"$cliJs`" start $argsStr"
    AE "AE-59 SPAWN_TARGET" $exec
  } elseif (Test-Path $expoCmd) {
    $exec = "`"$expoCmd`" start $argsStr"
    AE "AE-59 SPAWN_TARGET" $exec
  } else {
    AE "AE-52 CLI_NOT_FOUND" "fallback to npx expo"
    $exec = "npx expo start $argsStr"
  }

  $psCmd = "Set-Location `"$projectRoot`"; & $exec 2>&1 | Tee-Object -FilePath `"$startLog`""
  Log ("Open console started; log file: " + $startLog)
  Start-Process -FilePath "powershell.exe" -ArgumentList @("-NoLogo","-NoExit","-Command",$psCmd) -WindowStyle Normal | Out-Null

  # Heurystyka ?early exit? (je?li proces zamkn??by si? natychmiast ? w tym oknie zostanie log)
  Start-Sleep -Seconds 3
  if(!(Test-Path $startLog) -or ((Get-Item $startLog).Length -lt 50)){
    AE "AE-72 START_RETURNED_EARLY" "log too small or missing"
  }

  Log "Expo Go: w nowym oknie. Skanuj QR. Log: $startLog"
}
catch{
  AE "AE-54 START_FAILED" $_.Exception.Message
  Write-Host ("[ExpoGoStart-Error] " + $_.Exception.Message)
  exit 1
}
