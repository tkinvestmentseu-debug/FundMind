Param()
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir = Join-Path $projectRoot "logs"
if(-not (Test-Path $logsDir)){ New-Item -ItemType Directory -Force -Path $logsDir | Out-Null }
$timestamp = (Get-Date).ToString("yyyyMMdd-HHmmss")
$log = Join-Path $logsDir ("fundmind-ios-" + $timestamp + ".log")
function Log($m){ $line = "[" + (Get-Date).ToString("HH:mm:ss") + "] " + $m; Write-Host $line; Add-Content -Path $log -Value $line -Encoding UTF8 }
function Ensure-Dir($p){ if(-not (Test-Path $p)){ New-Item -ItemType Directory -Path $p -Force | Out-Null } }
Log "Start: FundMind iOS Fix & Run"
if(-not (Test-Path $projectRoot)) { throw "Project root not found: $projectRoot" }
Set-Location $projectRoot
Ensure-Dir (Join-Path $projectRoot "tools")
# Node/NPM versions
$node = (node --version) 2>$null
$npmv = (npm --version) 2>$null
Log ("Node: " + $node + ", npm: " + $npmv)
# Verify package.json
$pkgPath = Join-Path $projectRoot "package.json"
if(-not (Test-Path $pkgPath)) { throw ("package.json not found at " + $pkgPath) }
$pkg = Get-Content -Raw -Path $pkgPath | ConvertFrom-Json
function HasDep($obj,$name){ if($obj -eq $null){ return $false } return $obj.PSObject.Properties.Name -contains $name }
$usesDevClient = (HasDep $pkg.dependencies "expo-dev-client") -or (HasDep $pkg.devDependencies "expo-dev-client")
if($usesDevClient){ Log "Detected expo-dev-client -> Expo Go will NOT work. Use custom Dev Client on iOS." }
# Move config files from app/ to root if needed
$files = @("metro.config.js","babel.config.js","tsconfig.json")
foreach($f in $files){
  $src = Join-Path (Join-Path $projectRoot 'app') $f
  $dst = Join-Path $projectRoot $f
  if(Test-Path $src){
    if(Test-Path $dst){
      $bak = $src + ".bak." + $timestamp
      Log ("Backup app/" + $f + " -> " + $bak + " and remove duplicate")
      Copy-Item $src $bak -Force -Recurse
      Remove-Item $src -Force
    } else {
      Log ("Move app/" + $f + " -> " + $f)
      Move-Item $src $dst -Force
    }
  }
}
# Ensure babel.config.js
$babelPath = Join-Path $projectRoot "babel.config.js"
if(-not (Test-Path $babelPath)){
  Log "Create babel.config.js"
  $babelLines = @(
    'module.exports = function(api) {',
    '  api.cache(true);',
    '  return {',
    '    presets: ["babel-preset-expo"],',
    '    plugins: ["expo-router/babel"]',
    '  };',
    '};'
  )
  Set-Content -Path $babelPath -Value $babelLines -Encoding UTF8
} else {
  $babelText = Get-Content -Raw -Path $babelPath
  if(($babelText -notmatch "expo-router/babel") -or ($babelText -notmatch "babel-preset-expo")){
    $bak = $babelPath + ".bak." + $timestamp
    Log ("Backup and replace babel.config.js -> " + $bak)
    Copy-Item $babelPath $bak -Force
    $babelLines = @(
      'module.exports = function(api) {',
      '  api.cache(true);',
      '  return {',
      '    presets: ["babel-preset-expo"],',
      '    plugins: ["expo-router/babel"]',
      '  };',
      '};'
    )
    Set-Content -Path $babelPath -Value $babelLines -Encoding UTF8
  } else {
    Log "babel.config.js OK"
  }
}
# Ensure app.json
$appPath = Join-Path $projectRoot "app.json"
if(Test-Path $appPath){
  $app = Get-Content -Raw -Path $appPath | ConvertFrom-Json
} else {
  $app = [pscustomobject]@{ expo = [pscustomobject]@{} }
}
if(-not $app.expo){ $app | Add-Member -NotePropertyName expo -NotePropertyValue ([pscustomobject]@{}) }
if(-not $app.expo.runtimeVersion){
  $app.expo | Add-Member -NotePropertyName runtimeVersion -NotePropertyValue ([pscustomobject]@{ policy = "sdkVersion" })
} elseif(-not $app.expo.runtimeVersion.policy){
  $app.expo.runtimeVersion | Add-Member -NotePropertyName policy -NotePropertyValue "sdkVersion"
} else {
  $app.expo.runtimeVersion.policy = "sdkVersion"
}
if(-not $app.expo.sdkVersion){
  $app.expo | Add-Member -NotePropertyName sdkVersion -NotePropertyValue "50.0.0"
} else {
  $app.expo.sdkVersion = "50.0.0"
}
if(-not $app.expo.slug){ $app.expo | Add-Member -NotePropertyName slug -NotePropertyValue "fundmind" }
if(-not $app.expo.scheme){ $app.expo | Add-Member -NotePropertyName scheme -NotePropertyValue $app.expo.slug }
$app | ConvertTo-Json -Depth 100 | Set-Content -Path $appPath -Encoding UTF8
Log "app.json normalized"
# Clean install (avoid version drift)
$nm = Join-Path $projectRoot "node_modules"
if(Test-Path $nm){ Log "Remove node_modules"; Remove-Item $nm -Recurse -Force }
$pl = Join-Path $projectRoot "package-lock.json"
if(Test-Path $pl){ Log "Remove package-lock.json"; Remove-Item $pl -Force }
Log "npm install (can take a while)"
npm install 2>&1 | Tee-Object -FilePath $log -Append
Log "npx expo install core packages (align versions)"
npx expo install expo react react-native expo-router 2>&1 | Tee-Object -FilePath $log -Append
# Start dev server
$expoArgs = @("start","--tunnel")
if($env:CLEAR -eq "1"){ $expoArgs += "--clear"; Log "Metro cache clear enabled" }
Log "Starting Expo dev server with tunnel. Scan QR in Expo Go on iOS."
if($usesDevClient){ Log "Dev Client detected: use your custom Dev Client on iOS (Expo Go will not load native modules)." }
& npx expo @expoArgs 2>&1 | Tee-Object -FilePath $log -Append
