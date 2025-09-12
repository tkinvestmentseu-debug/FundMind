# fundmind-link-and-update.ps1 (Anti-Errors 36..45)

$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir     = "$projectRoot\logs"
$errorsLog   = "$logsDir\errors.log"

# ==> Ustalony, prawidlowy projectId z Twojego logu:
$projectId   = "ec364355-5e9f-4791-927f-f5fec18fbbde"

function Log-Info($m){ $t=Get-Date -Format s; Write-Host "[LinkUpdate] $m"; "$t [Info] $m"     | Out-File "$logsDir\update.log" -Encoding UTF8 -Append }
function Log-Error($m){ $t=Get-Date -Format s; Write-Host "[LinkUpdate-Error] $m"; "$t [AntiError] $m" | Out-File $errorsLog -Encoding UTF8 -Append }

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
  Log-Info "Start: sanitize JSON, pin deps, link by projectId, EAS update"

  # 1) Ensure babel/metro + reanimated plugin (Anti-Error #21, #45)
  $babelFile = Join-Path $projectRoot "babel.config.js"
  $babelOk = $false
  if (Test-Path $babelFile) {
    $babel = Get-Content $babelFile -Raw
    if ($babel -notmatch "expo-router/babel" -or $babel -notmatch "react-native-reanimated/plugin") {
      $babel = 'module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["expo-router/babel","react-native-reanimated/plugin"] }; };'
      Set-Content -Path $babelFile -Value $babel -Encoding UTF8
      Log-Info "Updated babel.config.js with reanimated plugin"
    } else { $babelOk = $true }
  } else {
    Set-Content -Path $babelFile -Encoding UTF8 -Value 'module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["expo-router/babel","react-native-reanimated/plugin"] }; };'
    Log-Info "Created babel.config.js"
  }

  $metroFile = Join-Path $projectRoot "metro.config.js"
  if (!(Test-Path $metroFile)) {
    Set-Content -Path $metroFile -Encoding UTF8 -Value 'const { getDefaultConfig }=require("expo/metro-config");const config=getDefaultConfig(__dirname);module.exports=config;'
    Log-Info "Created metro.config.js"
  }

  # 2) Remove BOMs (Anti-Error #36, #38)
  @("package.json","app.json","tsconfig.json","babel.config.js","metro.config.js") | ForEach-Object { Remove-BOM (Join-Path $projectRoot $_) }

  # 3) app.json: owner/slug/sdk/runtime + WPROWADZ POPRAWNY projectId (Anti-Error #31, #37, #44)
  $appJsonPath = Join-Path $projectRoot "app.json"
  if (!(Test-Path $appJsonPath)) { throw "app.json not found" }
  $app = Get-Content $appJsonPath -Raw | ConvertFrom-Json
  if (-not $app.expo){ $app | Add-Member -Name expo -MemberType NoteProperty -Value (@{}) }
  Ensure-Prop $app.expo "name" "FundMind"
  Ensure-Prop $app.expo "slug" "fundmind"
  Ensure-Prop $app.expo "owner" "tomasz77"
  Ensure-Prop $app.expo "sdkVersion" "50.0.0"
  Ensure-Prop $app.expo "runtimeVersion" (@{ policy = "sdkVersion" })
  if (-not ($app.expo.PSObject.Properties.Name -contains "extra")) { $app.expo | Add-Member -Name extra -MemberType NoteProperty -Value (@{}) }
  if (-not ($app.expo.extra.PSObject.Properties.Name -contains "eas")) { $app.expo.extra | Add-Member -Name eas -MemberType NoteProperty -Value (@{}) }
  $app.expo.extra.eas.projectId = $projectId  # <-- kluczowy wpis
  ($app | ConvertTo-Json -Depth 20) | Set-Content -Path $appJsonPath -Encoding UTF8
  Remove-BOM $appJsonPath
  Log-Info "app.json ensured with valid extra.eas.projectId"

  # 4) package.json: pin SDK50 + nav v6 + router entry; BEZ overrides (Anti-Error #40, #41, #42)
  $pkgPath = Join-Path $projectRoot "package.json"
  if (!(Test-Path $pkgPath)) { throw "package.json not found" }
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

  # Router entry / name
  Ensure-Prop $pkg "main" "expo-router/entry"
  Ensure-Prop $pkg "name" "fundmind"

  # Navigation v6 (zgodne z SDK50)
  Ensure-Dep $pkg.dependencies "@react-navigation/native"  "6.1.18"
  Ensure-Dep $pkg.dependencies "@react-navigation/drawer"  "6.5.8"

  # Natywne moduły
  Ensure-Dep $pkg.dependencies "react-native-gesture-handler" "2.12.0"
  Ensure-Dep $pkg.dependencies "react-native-reanimated"      "3.6.0"
  Ensure-Dep $pkg.dependencies "react-native-screens"         "3.29.0"
  Ensure-Dep $pkg.dependencies "react-native-safe-area-context" "4.8.2"

  # Test renderer tylko w dev
  if ($pkg.dependencies.PSObject.Properties.Name -contains "react-test-renderer"){ $pkg.dependencies.PSObject.Properties.Remove("react-test-renderer") }
  Ensure-Dep $pkg.devDependencies "react-test-renderer" "18.2.0"

  # Usuń overrides (Anti-Error #42)
  if ($pkg.PSObject.Properties.Name -contains "overrides"){ $pkg.PSObject.Properties.Remove("overrides"); Log-Info "Removed npm overrides" }

  ($pkg | ConvertTo-Json -Depth 30) | Set-Content -Path $pkgPath -Encoding UTF8
  Remove-BOM $pkgPath
  Log-Info "package.json pinned (SDK50 + nav6 + router entry, no overrides)"

  # 5) Clean install (unikamy ERESOLVE)
  if (Test-Path "$projectRoot\node_modules"){ Remove-Item -Recurse -Force "$projectRoot\node_modules" }
  if (Test-Path "$projectRoot\package-lock.json"){ Remove-Item -Force "$projectRoot\package-lock.json" }
  Log-Info "npm install --legacy-peer-deps"
  npm install --legacy-peer-deps
  if ($LASTEXITCODE -ne 0){ Log-Error "npm install failed"; exit 1 }

  # 6) Pomiń eas init — mamy prawidlowy projectId (Anti-Error #44)
  Log-Info "Skipping 'eas init' (valid projectId present)"

  # 7) Publikacja EAS Update
  Log-Info "Publishing with eas update (branch main)"
  npx eas-cli update --branch main --message "FundMind linked by projectId, nav v6, JSON sanitized"
  if ($LASTEXITCODE -ne 0){ Log-Error "eas update failed"; exit 1 }

  Log-Info "Completed successfully"
}
catch {
  Log-Error "Exception: $_"
  exit 1
}
