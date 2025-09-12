# fm-expo-go-start-v2.ps1
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir  = Join-Path $projectRoot "logs"
$antiErr = Join-Path $logsDir "antierrors.log"
function Log($m){ $t=Get-Date -Format s; Write-Host "[ExpoGoStart] $m"; "$t [Info] $m" | Out-File (Join-Path $logsDir "expo-start-summary.log") -Append -Encoding UTF8 }
function Save-AntiErr($code,$msg){ $t=Get-Date -Format s; "$t [$code] $msg" | Out-File $antiErr -Append -Encoding UTF8 }
function Remove-BOM($path){ if(Test-Path $path){ $raw=Get-Content $path -Raw -Encoding Byte; if($raw.Length-ge 3 -and $raw[0]-eq 239 -and $raw[1]-eq 187 -and $raw[2]-eq 191){ [IO.File]::WriteAllBytes($path,$raw[3..($raw.Length-1)]); Log "BOM removed: $(Split-Path $path -Leaf)" } } }
function Ensure-Babel-ForSDK($sdk){
  $babelFile = Join-Path $projectRoot "babel.config.js"
  if ($sdk -like "49.*") {
    $content = 'module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["expo-router/babel","react-native-reanimated/plugin"] }; };'
    Set-Content -Path $babelFile -Value $content -Encoding UTF8
    Log "babel.config.js -> SDK49 (WITH expo-router/babel)"
    return "--tunnel -c --force-manifest-type=classic"
  } else {
    $content = 'module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["react-native-reanimated/plugin"] }; };'
    Set-Content -Path $babelFile -Value $content -Encoding UTF8
    Log "babel.config.js -> SDK50+ (NO expo-router/babel)"
    return "--tunnel -c"
  }
}

try{
  Set-Location $projectRoot
  # 1) Sanity: BOM
  @("package.json","app.json","babel.config.js","metro.config.js","tsconfig.json") | ForEach-Object { Remove-BOM (Join-Path $projectRoot $_) }

  # 2) Odczytaj SDK i dobierz babel/args
  $appPath = Join-Path $projectRoot "app.json"
  if(!(Test-Path $appPath)){ throw "app.json not found" }
  $app = Get-Content $appPath -Raw | ConvertFrom-Json
  $sdk = if($app.expo -and $app.expo.sdkVersion){ $app.expo.sdkVersion } else { "49.0.0" }
  $startArgs = Ensure-Babel-ForSDK $sdk

  # 3) Upewnij main=expo-router/entry
  $pkgPath = Join-Path $projectRoot "package.json"
  if(Test-Path $pkgPath){ try{ $pkg=Get-Content $pkgPath -Raw | ConvertFrom-Json; if(-not ($pkg.PSObject.Properties.Name -contains "main") -or $pkg.main -ne "expo-router/entry"){ $pkg.main="expo-router/entry"; ($pkg|ConvertTo-Json -Depth 30) | Set-Content -Path $pkgPath -Encoding UTF8; Log "package.json: set main=expo-router/entry" } } catch { Save-AntiErr "JSON" "package.json invalid: $($_.Exception.Message)" } }

  # 4) PATH/COMSPEC oraz brak WSL
  $env:COMSPEC = "$env:SystemRoot\System32\cmd.exe"
  $sys32 = "$env:SystemRoot\System32"
  $ps10  = "$env:SystemRoot\System32\WindowsPowerShell\v1.0"
  $gitBin= "C:\Program Files\Git\bin"
  $nodeCmd = (Get-Command node.exe -ErrorAction SilentlyContinue)
  $npmCmd  = (Get-Command npm.cmd  -ErrorAction SilentlyContinue)
  $add = @()
  if($nodeCmd){ $add += (Split-Path $nodeCmd.Source) }
  if($npmCmd){  $add += (Split-Path $npmCmd.Source) }
  $add += $sys32; $add += $ps10; if(Test-Path $gitBin){ $add += $gitBin }
  $env:PATH = (($add + $env:PATH) -join ";")
  $wsl = (Get-Command wsl.exe -ErrorAction SilentlyContinue)
  if(-not $wsl){ $env:EXPO_NO_WSL = "1"; Log "EXPO_NO_WSL=1 (wsl.exe not found)" }
  $env:BROWSER="none"; $env:EXPO_NO_DOCTOR="1"; $env:npm_config_legacy_peer_deps="true"

  # 5) Caches
  if(Test-Path ".\.expo"){ Remove-Item -Recurse -Force ".\.expo" }
  if(Test-Path ".\.expo-shared"){ Remove-Item -Recurse -Force ".\.expo-shared" }

  # 6) Start CLI bez npx (stabilniej): node node_modules\expo\bin\cli.js
  $cliJs = Join-Path $projectRoot "node_modules\expo\bin\cli.js"
  if(!(Test-Path $cliJs)){ throw "CLI not found: $cliJs (run npm i)" }
  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
  $startLog = Join-Path $logsDir ("expo-start-{0}.log" -f $ts)
  Log ("Starting: node `" + $cliJs + "` start " + $startArgs)
  Log ("Log file: " + $startLog)
  try{
    & cmd.exe /c "node `"$cliJs`" start $startArgs" *>&1 | Tee-Object -FilePath $startLog
  } catch {
    Save-AntiErr "SPAWN" "spawn failed: $($_.Exception.Message)"
    throw
  }
} catch {
  Save-AntiErr "FATAL" "$($_.Exception.Message)"
  Write-Host "[ExpoGoStart-Error] $($_.Exception.Message)"
  exit 1
}
