# fm-expo-go-start-v10.ps1
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

# AE-50: poprawny babel dla SDK (USUNI?TO b??dn? flag? --no-dev-tools)
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

# AE-63 PATH hardening + AE-65 unset CI
function Harden-Env(){
  $global:LASTEXITCODE=0
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
  $env:CI = ""
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

  # Env, deps, shims, cache
  Harden-Env
  if(!(Get-Command node.exe -ErrorAction SilentlyContinue)){ AE "AE-66 NODE_MISSING" "node.exe not found in PATH"; throw "node.exe not found" }
  if(!(Get-Command npm.cmd -ErrorAction SilentlyContinue)){ AE "AE-66 NPM_MISSING" "npm.cmd not found in PATH"; throw "npm.cmd not found" }
  Ensure-Expo $sdk
  Ensure-Shims
  if(Test-Path ".\.expo"){ Remove-Item -Recurse -Force ".\.expo" }
  if(Test-Path ".\.expo-shared"){ Remove-Item -Recurse -Force ".\.expo-shared" }

  # Start
  $cliJs  = Find-ExpoCLI
  $expoCmd= Join-Path $projectRoot "node_modules\.bin\expo.cmd"
  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
  $startLog = Join-Path $logsDir ("expo-start-{0}.log" -f $ts)

  "=== ENV SNAPSHOT ===" | Out-File $startLog -Encoding UTF8
  ("NODE="+((Get-Command node).Source)) | Out-File $startLog -Append
  ("NPM ="+((Get-Command npm).Source))  | Out-File $startLog -Append
  ("PATH="+$env:PATH) | Out-File $startLog -Append
  "" | Out-File $startLog -Append

  if($cliJs){
    $allArgs = @($cliJs,"start") + $argsArr
    AE "AE-59 SPAWN_TARGET" ("node "+($allArgs -join " "))
    Log ("Starting (cli): node "+($allArgs -join " "))
    & node $allArgs 2>&1 | Tee-Object -FilePath $startLog
  } elseif (Test-Path $expoCmd) {
    AE "AE-52 CLI_NOT_FOUND" "fallback to .bin\expo.cmd"
    $allArgs = @("start") + $argsArr
    Log ("Starting (.bin\expo): " + $expoCmd + " " + ($allArgs -join " "))
    & $expoCmd $allArgs 2>&1 | Tee-Object -FilePath $startLog
  } else {
    AE "AE-52 CLI_NOT_FOUND" "fallback to npx expo"
    $allArgs = @("expo","start") + $argsArr
    Log ("Starting (npx): npx "+($allArgs -join " "))
    & npx $allArgs 2>&1 | Tee-Object -FilePath $startLog
  }
}
catch{
  AE "AE-54 START_FAILED" $_.Exception.Message
  Write-Host ("[ExpoGoStart-Error] " + $_.Exception.Message)
  exit 1
}
