# fundmind-fix-nav-and-update.ps1  (Anti-Errors: 21,26,31,33,36..41)

$projectRoot = "D:\FundMind"
$logsDir = "$projectRoot\logs"
$errorsLog = "$logsDir\errors.log"

function Log-Info($m){ $t=Get-Date -Format s; Write-Host "[FixNAV] $m"; "$t [Info] $m" | Out-File "$logsDir\update.log" -Encoding UTF8 -Append }
function Log-Error($m){ $t=Get-Date -Format s; Write-Host "[FixNAV-Error] $m"; "$t [AntiError] $m" | Out-File $errorsLog -Encoding UTF8 -Append }

function Ensure-Prop($obj,$name,$value){
  if (-not ($obj.PSObject.Properties.Name -contains $name)){ $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value }
  else { $obj.$name = $value }
}

function Remove-BOM($path){
  if (Test-Path $path){
    $raw = Get-Content $path -Raw -Encoding Byte
    if ($raw.Length -ge 3 -and $raw[0] -eq 239 -and $raw[1] -eq 187 -and $raw[2] -eq 191){
      $clean = $raw[3..($raw.Length-1)]
      [IO.File]::WriteAllBytes($path,$clean)
      Log-Info "Removed BOM from $(Split-Path $path -Leaf)"
    }
  }
}

try {
  Set-Location $projectRoot
  Log-Info "Start fix nav deps + EAS update"

  # 1) Sanity: configs exist (Anti-Error #21)
  if (!(Test-Path (Join-Path $projectRoot "babel.config.js"))) {
    Set-Content -Path (Join-Path $projectRoot "babel.config.js") -Encoding UTF8 -Value 'module.exports=function(api){api.cache(true);return{presets:["babel-preset-expo"],plugins:["expo-router/babel"]};};'
    Log-Info "Created babel.config.js"
  }
  if (!(Test-Path (Join-Path $projectRoot "metro.config.js"))) {
    Set-Content -Path (Join-Path $projectRoot "metro.config.js") -Encoding UTF8 -Value 'const { getDefaultConfig }=require("expo/metro-config");const config=getDefaultConfig(__dirname);module.exports=config;'
    Log-Info "Created metro.config.js"
  }

  # 2) Remove BOM from JSON/configs (Anti-Error #36, #38)
  @("package.json","app.json","tsconfig.json","babel.config.js","metro.config.js") | ForEach-Object { Remove-BOM (Join-Path $projectRoot $_) }

  # 3) Ensure app.json + drop stale projectId (Anti-Error #31, #37)
  $appJsonPath = Join-Path $projectRoot "app.json"
  if (!(Test-Path $appJsonPath)) { throw "app.json not found" }
  $app = Get-Content $appJsonPath -Raw | ConvertFrom-Json
  if (-not $app.expo){ $app | Add-Member -Name expo -MemberType NoteProperty -Value (@{}) }
  Ensure-Prop $app.expo "name" "FundMind"
  Ensure-Prop $app.expo "slug" "fundmind"
  Ensure-Prop $app.expo "owner" "tomasz77"
  Ensure-Prop $app.expo "sdkVersion" "50.0.0"
  Ensure-Prop $app.expo "runtimeVersion" (@{ policy = "sdkVersion" })
  if ($app.expo.PSObject.Properties.Name -contains "extra"){
    if ($app.expo.extra.PSObject.Properties.Name -contains "eas"){
      $app.expo.extra.PSObject.Properties.Remove("eas")
      Log-Info "Removed stale extra.eas.projectId"
    }
  }
  ($app | ConvertTo-Json -Depth 10) | Set-Content -Path $appJsonPath -Encoding UTF8
  Log-Info "app.json ensured"

  # 4) Pin package.json to SDK 50 + router + navigation 6.x (Anti-Errors #26, #40, #41)
  $pkgPath = Join-Path $projectRoot "package.json"
  $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
  if (-not $pkg.dependencies)   { $pkg | Add-Member -Name dependencies   -MemberType NoteProperty -Value (@{}) }
  if (-not $pkg.devDependencies){ $pkg | Add-Member -Name devDependencies -MemberType NoteProperty -Value (@{}) }

  function Ensure-Dep($deps,$k,$v){ if (-not ($deps.PSObject.Properties.Name -contains $k)){ $deps | Add-Member -NotePropertyName $k -NotePropertyValue $v } else { $deps.$k = $v } }
  # Core
  Ensure-Dep $pkg.dependencies "expo" "~50.0.0"
  Ensure-Dep $pkg.dependencies "expo-router" "~3.4.10"
  Ensure-Dep $pkg.dependencies "react" "18.2.0"
  Ensure-Dep $pkg.dependencies "react-dom" "18.2.0"
  Ensure-Dep $pkg.dependencies "react-native" "0.73.6"
  # Router entry
  Ensure-Prop $pkg "main" "expo-router/entry"
  Ensure-Prop $pkg "name" "fundmind"
  # Navigation pinned 6.x (avoid v7 which requires screens >=4)
  Ensure-Dep $pkg.dependencies "@react-navigation/native" "^6.1.18"
  Ensure-Dep $pkg.dependencies "@react-navigation/drawer" "^6.5.8"
  # Native deps (we'll align via expo install)
  Ensure-Dep $pkg.dependencies "react-native-screens" "~3.29.0"
  Ensure-Dep $pkg.dependencies "react-native-safe-area-context" "4.8.2"
  Ensure-Dep $pkg.dependencies "react-native-gesture-handler" "^2.12.0"
  Ensure-Dep $pkg.dependencies "react-native-reanimated" "~3.6.0"
  # Test renderer only in dev
  if ($pkg.dependencies.PSObject.Properties.Name -contains "react-test-renderer"){
    $pkg.dependencies.PSObject.Properties.Remove("react-test-renderer")
  }
  Ensure-Dep $pkg.devDependencies "react-test-renderer" "18.2.0"

  # Optional: overrides to enforce nav 6.x if resolver upshifts
  Ensure-Prop $pkg "overrides" (@{})
  $pkg.overrides."@react-navigation/native" = "6.1.18"
  $pkg.overrides."@react-navigation/drawer" = "6.5.8"

  ($pkg | ConvertTo-Json -Depth 20) | Set-Content -Path $pkgPath -Encoding UTF8
  Remove-BOM $pkgPath
  Log-Info "package.json pinned (SDK50 + router entry + nav 6.x)"

  # 5) Clean install (avoid peer fights)
  if (Test-Path "$projectRoot\node_modules"){ Remove-Item -Recurse -Force "$projectRoot\node_modules" }
  if (Test-Path "$projectRoot\package-lock.json"){ Remove-Item -Force "$projectRoot\package-lock.json" }
  Log-Info "npm install clean"
  npm install --legacy-peer-deps
  if ($LASTEXITCODE -ne 0){ Log-Error "npm install failed"; exit 1 }

  # 6) Align native modules only (no @react-navigation here!)
  Log-Info "expo install native deps align"
  npx expo install react-native-gesture-handler react-native-reanimated react-native-safe-area-context react-native-screens
  if ($LASTEXITCODE -ne 0){ Log-Error "expo install native deps failed"; exit 1 }

  # 7) EAS login/init
  Log-Info "Check EAS login"
  npx eas-cli whoami
  if ($LASTEXITCODE -ne 0){ npx eas-cli login; if ($LASTEXITCODE -ne 0){ Log-Error "eas login failed"; exit 1 } }

  if (!(Test-Path "$projectRoot\.eas")){
    Log-Info "Running eas init"
    npx eas-cli init --non-interactive
    if ($LASTEXITCODE -ne 0){ Log-Error "eas init failed"; exit 1 }
  } else {
    Log-Info "EAS project already linked"
  }

  # 8) Publish with EAS Update
  Log-Info "Publishing with eas update (branch main)"
  npx eas-cli update --branch main --message "FundMind pinned nav 6.x and fixed JSON"
  if ($LASTEXITCODE -ne 0){ Log-Error "eas update failed"; exit 1 }

  Log-Info "Completed successfully"
}
catch {
  Log-Error "Exception: $_"
  exit 1
}
