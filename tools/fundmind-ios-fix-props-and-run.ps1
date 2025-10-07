Param()
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir = Join-Path $projectRoot "logs"
if(-not (Test-Path $logsDir)){ New-Item -ItemType Directory -Force -Path $logsDir | Out-Null }
$ts = (Get-Date).ToString("yyyyMMdd-HHmmss")
$log = Join-Path $logsDir ("fundmind-ios-" + $ts + ".log")
function Log($m){ $line = "[" + (Get-Date).ToString("HH:mm:ss") + "] " + $m; Write-Host $line; Add-Content -Path $log -Value $line -Encoding UTF8 }
function HasProp($obj,$name){ if($null -eq $obj){ return $false }; return $obj.PSObject.Properties.Name -contains $name }
function Ensure-Prop($obj,[string]$name,$value){ if(-not (HasProp $obj $name)){ $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value } else { $obj.$name = $value } }
Log "Start fix"
Set-Location $projectRoot
# Move misplaced config files from app/ to root
$cfgs = @("metro.config.js","babel.config.js","tsconfig.json")
foreach($f in $cfgs){
  $src = Join-Path (Join-Path $projectRoot "app") $f
  $dst = Join-Path $projectRoot $f
  if(Test-Path $src){
    if(Test-Path $dst){
      $bak = $src + ".bak." + $ts
      Copy-Item $src $bak -Force
      Remove-Item $src -Force
      Log ("Removed duplicate app\" + $f + " (backup saved)")
    } else {
      Move-Item $src $dst -Force
      Log ("Moved app\" + $f + " to root")
    }
  }
}
# package.json fix via Add-Member
$pkgPath = Join-Path $projectRoot "package.json"
if(-not (Test-Path $pkgPath)){ throw ("package.json not found: " + $pkgPath) }
$pkg = Get-Content -Raw -Path $pkgPath | ConvertFrom-Json
if(-not (HasProp $pkg "dependencies"))    { $pkg | Add-Member -NotePropertyName dependencies    -NotePropertyValue ([pscustomobject]@{}) }
if(-not (HasProp $pkg "devDependencies")) { $pkg | Add-Member -NotePropertyName devDependencies -NotePropertyValue ([pscustomobject]@{}) }
function Ensure-Dep($name,$ver){ Ensure-Prop $pkg.dependencies $name $ver }
function Ensure-DevDep($name,$ver){ Ensure-Prop $pkg.devDependencies $name $ver }
Ensure-Dep "expo" "~50.0.17"
Ensure-Dep "expo-router" "~3.4.8"
Ensure-Dep "react" "18.2.0"
Ensure-Dep "react-native" "0.73.6"
Ensure-DevDep "babel-preset-expo" "~9.5.2"
$usesDevClient = (HasProp $pkg.dependencies "expo-dev-client") -or (HasProp $pkg.devDependencies "expo-dev-client")
($pkg | ConvertTo-Json -Depth 100) | Set-Content -Path $pkgPath -Encoding UTF8
Log "package.json normalized (UTF-8, no BOM)"
# babel.config.js ensure
$babelPath = Join-Path $projectRoot "babel.config.js"
if(-not (Test-Path $babelPath)){
  $babel = @(
    "module.exports = function(api) {",
    "  api.cache(true);",
    "  return {",
    "    presets: ['babel-preset-expo'],",
    "    plugins: ['expo-router/babel']",
    "  };",
    "};"
  )
  Set-Content -Path $babelPath -Value $babel -Encoding UTF8
  Log "babel.config.js created"
} else {
  $txt = Get-Content -Raw -Path $babelPath
  if(($txt -notmatch "expo-router/babel") -or ($txt -notmatch "babel-preset-expo")){
    $bak = $babelPath + ".bak." + $ts
    Copy-Item $babelPath $bak -Force
    $babel = @(
      "module.exports = function(api) {",
      "  api.cache(true);",
      "  return {",
      "    presets: ['babel-preset-expo'],",
      "    plugins: ['expo-router/babel']",
      "  };",
      "};"
    )
    Set-Content -Path $babelPath -Value $babel -Encoding UTF8
    Log "babel.config.js replaced (backup saved)"
  } else { Log "babel.config.js OK" }
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
# Clean install
$nm = Join-Path $projectRoot "node_modules"
if(Test-Path $nm){ Log "Remove node_modules"; Remove-Item $nm -Recurse -Force }
$pl = Join-Path $projectRoot "package-lock.json"
if(Test-Path $pl){ Log "Remove package-lock.json"; Remove-Item $pl -Force }
Log "npm install"
npm install 2>&1 | Tee-Object -FilePath $log -Append
Log "expo install core (align versions)"
npx expo install expo react react-native expo-router 2>&1 | Tee-Object -FilePath $log -Append
if($usesDevClient){ Log "Detected expo-dev-client: use a custom Dev Client on iOS (Expo Go will not load native modules)" }
$args = @("start","--tunnel")
if($env:CLEAR -eq "1"){ $args += "--clear"; Log "Metro cache clear enabled" }
Log "Starting Expo dev server..."
& npx expo @args 2>&1 | Tee-Object -FilePath $log -Append
