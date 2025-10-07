Param()
$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false
$projectRoot = "D:\FundMind"
$logsDir = Join-Path $projectRoot "logs"
if(-not (Test-Path $logsDir)){ New-Item -ItemType Directory -Force -Path $logsDir | Out-Null }
$ts = (Get-Date).ToString("yyyyMMdd-HHmmss")
$log = Join-Path $logsDir ("fundmind-ios-" + $ts + ".log")
function Log($m){ $line = "[" + (Get-Date).ToString("HH:mm:ss") + "] " + $m; Write-Host $line; Add-Content -Path $log -Value $line -Encoding UTF8 }
function HasProp($o,$n){ if($null -eq $o){ return $false }; return $o.PSObject.Properties.Name -contains $n }
function Ensure-Prop($o,[string]$n,$v){ if(-not (HasProp $o $n)){ $o | Add-Member -NotePropertyName $n -NotePropertyValue $v } else { $o.$n = $v } }
function Run-Proc($exe,[string[]]$argv){ $argstr = ""; if($argv){ $argstr = ($argv -join " ") }; Log ("Run: " + $exe + " " + $argstr); & $exe @argv *>&1 | Tee-Object -FilePath $log -Append; if($LASTEXITCODE -ne 0){ throw ($exe + " failed with exit code " + $LASTEXITCODE) } }
Log "Start fix"
Set-Location $projectRoot
# Move misplaced config files from app/ to root
$cfgs = @("metro.config.js","babel.config.js","tsconfig.json")
foreach($f in $cfgs){ $src = Join-Path (Join-Path $projectRoot "app") $f; $dst = Join-Path $projectRoot $f; if(Test-Path $src){ if(Test-Path $dst){ Copy-Item $src ($src + ".bak." + $ts) -Force; Remove-Item $src -Force; Log ("Removed duplicate app\" + $f) } else { Move-Item $src $dst -Force; Log ("Moved app\" + $f + " to root") } } }
# package.json ensure
$pkgPath = Join-Path $projectRoot "package.json"
if(-not (Test-Path $pkgPath)){ throw ("package.json not found: " + $pkgPath) }
$pkg = Get-Content -Raw -Path $pkgPath | ConvertFrom-Json
if(-not (HasProp $pkg "dependencies"))    { $pkg | Add-Member -NotePropertyName dependencies    -NotePropertyValue ([pscustomobject]@{}) }
if(-not (HasProp $pkg "devDependencies")) { $pkg | Add-Member -NotePropertyName devDependencies -NotePropertyValue ([pscustomobject]@{}) }
Ensure-Prop $pkg "main" "expo-router/entry"
function Ensure-Dep($n,$v){ Ensure-Prop $pkg.dependencies $n $v }
function Ensure-DevDep($n,$v){ Ensure-Prop $pkg.devDependencies $n $v }
Ensure-Dep "expo" "~50.0.17"
Ensure-Dep "expo-router" "~3.4.8"
Ensure-Dep "react" "18.2.0"
Ensure-Dep "react-native" "0.73.6"
Ensure-DevDep "babel-preset-expo" "~9.5.2"
$usesDevClient = (HasProp $pkg.dependencies "expo-dev-client") -or (HasProp $pkg.devDependencies "expo-dev-client")
($pkg | ConvertTo-Json -Depth 100) | Set-Content -Path $pkgPath -Encoding UTF8
Log "package.json normalized"
# babel.config.js ensure
$babelPath = Join-Path $projectRoot "babel.config.js"
if(-not (Test-Path $babelPath)){
  $babel = @("module.exports = function(api) {","  api.cache(true);","  return {","    presets: ['babel-preset-expo'],","    plugins: ['expo-router/babel']","  };","};")
  Set-Content -Path $babelPath -Value $babel -Encoding UTF8
  Log "babel.config.js created"
} else {
  $txt = Get-Content -Raw -Path $babelPath
  if(($txt -notmatch "expo-router/babel") -or ($txt -notmatch "babel-preset-expo")){ Copy-Item $babelPath ($babelPath + ".bak." + $ts) -Force; $babel = @("module.exports = function(api) {","  api.cache(true);","  return {","    presets: ['babel-preset-expo'],","    plugins: ['expo-router/babel']","  };","};"); Set-Content -Path $babelPath -Value $babel -Encoding UTF8; Log "babel.config.js replaced" }
  else { Log "babel.config.js OK" }
}
# app.json ensure
$appPath = Join-Path $projectRoot "app.json"
if(Test-Path $appPath){ $app = Get-Content -Raw -Path $appPath | ConvertFrom-Json } else { $app = [pscustomobject]@{} }
if(-not (HasProp $app "expo")){ $app | Add-Member -NotePropertyName expo -NotePropertyValue ([pscustomobject]@{}) }
Ensure-Prop $app.expo "name" "FundMind"
Ensure-Prop $app.expo "slug" "fundmind"
Ensure-Prop $app.expo "version" "1.0.0"
Ensure-Prop $app.expo "sdkVersion" "50.0.0"
if(-not (HasProp $app.expo "platforms")){ $app.expo | Add-Member -NotePropertyName platforms -NotePropertyValue @("ios","android","web") }
if(-not (HasProp $app.expo "runtimeVersion")){ $app.expo | Add-Member -NotePropertyName runtimeVersion -NotePropertyValue ([pscustomobject]@{}) }
Ensure-Prop $app.expo.runtimeVersion "policy" "sdkVersion"
($app | ConvertTo-Json -Depth 100) | Set-Content -Path $appPath -Encoding UTF8
Log "app.json normalized"
# clean install
$nm = Join-Path $projectRoot "node_modules"
if(Test-Path $nm){ Log "Remove node_modules"; Remove-Item $nm -Recurse -Force }
$pl = Join-Path $projectRoot "package-lock.json"
if(Test-Path $pl){ Log "Remove package-lock.json"; Remove-Item $pl -Force }
Run-Proc "npm" @("install")
Run-Proc "npx" @("expo","install","expo","react","react-native","expo-router")
if($usesDevClient){ Log "Detected expo-dev-client: use custom Dev Client on iOS (Expo Go will not load native modules)" }
$expoArgs = @("start","--tunnel")
if($env:CLEAR -eq "1"){ $expoArgs += "--clear"; Log "Metro cache clear enabled" }
Log "Starting Expo dev server..."
& npx expo @expoArgs
