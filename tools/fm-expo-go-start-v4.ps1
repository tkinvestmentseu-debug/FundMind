# fm-expo-go-start-v4.ps1
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir  = Join-Path $projectRoot "logs"
$antiErr = Join-Path $logsDir "antierrors.log"
function Log($m){ $t=Get-Date -Format s; Write-Host "[ExpoGoStart] $m"; "$t [Info] $m" | Out-File (Join-Path $logsDir "expo-start-summary.log") -Append -Encoding UTF8 }
function Save-AE($code,$msg){ $t=Get-Date -Format s; "$t [$code] $msg" | Out-File $antiErr -Append -Encoding UTF8 }
function Remove-BOM($path){ if(Test-Path $path){ $raw=Get-Content $path -Raw -Encoding Byte; if($raw.Length-ge 3 -and $raw[0]-eq 239 -and $raw[1]-eq 187 -and $raw[2]-eq 191){ [IO.File]::WriteAllBytes($path,$raw[3..($raw.Length-1)]); Log ("BOM removed: " + (Split-Path $path -Leaf)) } } }
function Ensure-Babel-ForSDK($sdk){ $babelFile = Join-Path $projectRoot "babel.config.js"; if($sdk -like "49.*"){ $c='module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["expo-router/babel","react-native-reanimated/plugin"] }; };' } else { $c='module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["react-native-reanimated/plugin"] }; };' } ; Set-Content -Path $babelFile -Value $c -Encoding UTF8; if($sdk -like "49.*"){ Log "babel.config.js -> SDK49 (WITH expo-router/babel)"} else { Log "babel.config.js -> SDK50+ (NO expo-router/babel)"} }
function Ensure-ExpoInstalled($sdk){
  $pkgPath = Join-Path $projectRoot "package.json"
  if(!(Test-Path $pkgPath)){ throw "package.json not found" }
  try { $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json } catch { Save-AE "AE-49-JSON" ("package.json invalid: " + $_.Exception.Message); throw }
  if(-not $pkg.dependencies){ $pkg | Add-Member -Name dependencies -MemberType NoteProperty -Value (@{}) }
  $desired = if($sdk -like "49.*"){ "~49.0.21" } elseif($sdk -like "50.*"){ "~50.0.0" } else { "~50.0.0" }
  if(-not ($pkg.dependencies.PSObject.Properties.Name -contains "expo") -or $pkg.dependencies.expo -notlike $desired){
    $pkg.dependencies.expo = $desired
    ($pkg | ConvertTo-Json -Depth 30) | Set-Content -Path $pkgPath -Encoding UTF8
    Log ("Pinned expo " + $desired + " (AE-55 SDK_MISMATCH)")
  }
  # Clean install jeżeli brakuje expo
  $expoDir = Join-Path $projectRoot "node_modules\expo"
  if(!(Test-Path $expoDir)){
    if(Test-Path (Join-Path $projectRoot "node_modules")){ Remove-Item -Recurse -Force (Join-Path $projectRoot "node_modules") }
    if(Test-Path (Join-Path $projectRoot "package-lock.json")){ Remove-Item -Force (Join-Path $projectRoot "package-lock.json") }
    Log "npm install (legacy-peer-deps) — installing expo locally"
    npm install --legacy-peer-deps
    if($LASTEXITCODE -ne 0){ Save-AE "AE-53 NPM_INSTALL_FAILED" "npm install exit $LASTEXITCODE"; throw "npm install failed ($LASTEXITCODE)" }
  }
}

try {
  Set-Location $projectRoot
  @("package.json","app.json","babel.config.js","metro.config.js","tsconfig.json") | ForEach-Object { Remove-BOM (Join-Path $projectRoot $_) }
  $appPath = Join-Path $projectRoot "app.json"; if(!(Test-Path $appPath)){ throw "app.json not found" }
  $app = Get-Content $appPath -Raw | ConvertFrom-Json
  $sdk = if($app.expo -and $app.expo.sdkVersion){ $app.expo.sdkVersion } else { "49.0.0" }
  Ensure-Babel-ForSDK $sdk
  # PATH/COMSPEC/WSL
  $env:COMSPEC = "$env:SystemRoot\System32\cmd.exe"
  $sys32="$env:SystemRoot\System32"; $ps10="$env:SystemRoot\System32\WindowsPowerShell\v1.0"; $gitBin="C:\Program Files\Git\bin"
  $nodeCmd=(Get-Command node.exe -ErrorAction SilentlyContinue); $npmCmd=(Get-Command npm.cmd -ErrorAction SilentlyContinue)
  $add=@(); if($nodeCmd){$add+=(Split-Path $nodeCmd.Source)}; if($npmCmd){$add+=(Split-Path $npmCmd.Source)}; $add+=$sys32; $add+=$ps10; if(Test-Path $gitBin){$add+=$gitBin}; $env:PATH=(($add+$env:PATH)-join ";")
  if(-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)){ $env:EXPO_NO_WSL="1"; Log "EXPO_NO_WSL=1" }
  $env:BROWSER="none"; $env:EXPO_NO_DOCTOR="1"; $env:npm_config_legacy_peer_deps="true"

  # Upewnij expo w node_modules
  Ensure-ExpoInstalled $sdk

  # Preferencje kolejności startu: cli.js -> .bin\expo.cmd -> npx expo
  $cliJs = Join-Path $projectRoot "node_modules\expo\bin\cli.js"
  $expoCmd = Join-Path $projectRoot "node_modules\.bin\expo.cmd"
  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
  $startLog = Join-Path $logsDir ("expo-start-{0}.log" -f $ts)
  $args49 = "--tunnel -c --force-manifest-type=classic"
  $args50 = "--tunnel -c"
  $startArgs = if($sdk -like "49.*"){ $args49 } else { $args50 }

  if(Test-Path $cliJs){
    $cmdLine = 'node "{0}" start {1}' -f $cliJs, $startArgs
    Log ("Starting (cli.js): " + $cmdLine); Log ("Log file: " + $startLog)
    & cmd.exe /c $cmdLine *>&1 | Tee-Object -FilePath $startLog
  } elseif (Test-Path $expoCmd) {
    Save-AE "AE-52 CLI_NOT_FOUND" "fallback to .bin\expo.cmd"
    $cmdLine = '"{0}" start {1}' -f $expoCmd, $startArgs
    Log ("Starting (.bin\expo.cmd): " + $cmdLine); Log ("Log file: " + $startLog)
    & cmd.exe /c $cmdLine *>&1 | Tee-Object -FilePath $startLog
  } else {
    Save-AE "AE-52 CLI_NOT_FOUND" "fallback to npx expo"
    $cmdLine = 'npx expo start {0}' -f $startArgs
    Log ("Starting (npx expo): " + $cmdLine); Log ("Log file: " + $startLog)
    & cmd.exe /c $cmdLine *>&1 | Tee-Object -FilePath $startLog
  }
} catch {
  Save-AE "AE-54 START_FAILED" ($_.Exception.Message)
  Write-Host ("[ExpoGoStart-Error] " + $_.Exception.Message)
  exit 1
}
