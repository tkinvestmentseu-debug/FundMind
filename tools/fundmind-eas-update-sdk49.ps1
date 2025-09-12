# fundmind-eas-update-sdk49.ps1 — publikacja SDK49 do Expo Go (bez expo start)
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir     = "$projectRoot\logs"
$errorsLog   = "$logsDir\errors.log"

function Log($m){ $t=Get-Date -Format s; Write-Host "[EAS49] $m"; "$t [Info] $m" | Out-File "$logsDir\eas49.log" -Encoding UTF8 -Append }
function LogErr($m){ $t=Get-Date -Format s; Write-Host "[EAS49-Error] $m"; "$t [AntiError] $m" | Out-File $errorsLog -Encoding UTF8 -Append }

function Remove-BOM($path){
  if (Test-Path $path){
    $raw = Get-Content $path -Raw -Encoding Byte
    if ($raw.Length -ge 3 -and $raw[0] -eq 239 -and $raw[1] -eq 187 -and $raw[2] -eq 191){
      $clean = $raw[3..($raw.Length-1)]
      [IO.File]::WriteAllBytes($path,$clean)
      Log "Removed BOM from $(Split-Path $path -Leaf)"
    }
  }
}

function Ensure-Prop($obj,$name,$value){
  if (-not ($obj.PSObject.Properties.Name -contains $name)){
    $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value
  } else { $obj.$name = $value }
}

try {
  Set-Location $projectRoot
  Log "Start EAS Update SDK49 (Expo Go)"

  # 0) Sanity: babel (bez deprecated pluginów)
  $babelFile = Join-Path $projectRoot "babel.config.js"
  $babelSafe = 'module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["react-native-reanimated/plugin"] }; };'
  Set-Content -Path $babelFile -Encoding UTF8 -Value $babelSafe

  # 1) app.json → SDK 49, runtimeVersion policy, owner/slug, projectId
  $appPath = Join-Path $projectRoot "app.json"
  if (!(Test-Path $appPath)) { throw "app.json not found" }
  $app = Get-Content $appPath -Raw | ConvertFrom-Json
  if (-not $app.expo){ $app | Add-Member -Name expo -MemberType NoteProperty -Value (@{}) }
  $app.expo.name = "FundMind"
  $app.expo.slug = "fundmind"
  $app.expo.owner = "tomasz77"
  $app.expo.sdkVersion = "49.0.0"
  $app.expo.runtimeVersion = @{ policy = "sdkVersion" }
  # Upewnij się, że extra.eas.projectId istnieje (z poprzednich logów):
  if (-not ($app.expo.PSObject.Properties.Name -contains "extra")) { $app.expo | Add-Member -Name extra -MemberType NoteProperty -Value (@{}) }
  if (-not ($app.expo.extra.PSObject.Properties.Name -contains "eas")) { $app.expo.extra | Add-Member -Name eas -MemberType NoteProperty -Value (@{}) }
  if (-not ($app.expo.extra.eas.PSObject.Properties.Name -contains "projectId")) {
    $app.expo.extra.eas | Add-Member -Name projectId -MemberType NoteProperty -Value "ec364355-5e9f-4791-927f-f5fec18fbbde"
    Log "Injected EAS projectId ec364355-5e9f-4791-927f-f5fec18fbbde"
  }
  ($app | ConvertTo-Json -Depth 10) | Set-Content -Path $appPath -Encoding UTF8
  Remove-BOM $appPath
  Log "app.json set to SDK 49"

  # 2) package.json → pin SDK49 deps + usuń expo-dev-client
  $pkgPath = Join-Path $projectRoot "package.json"
  if (!(Test-Path $pkgPath)) { throw "package.json not found" }
  $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
  if (-not $pkg.dependencies){ $pkg | Add-Member -Name dependencies -MemberType NoteProperty -Value (@{}) }
  if (-not $pkg.devDependencies){ $pkg | Add-Member -Name devDependencies -MemberType NoteProperty -Value (@{}) }

  $pkg.dependencies.expo = "~49.0.21"
  $pkg.dependencies."expo-router" = "~3.4.8"
  $pkg.dependencies.react = "18.2.0"
  $pkg.dependencies."react-dom" = "18.2.0"
  $pkg.dependencies."react-native" = "0.72.10"
  $pkg.dependencies."react-native-screens" = "3.27.0"
  $pkg.dependencies."react-native-safe-area-context" = "4.6.3"
  $pkg.dependencies."react-native-gesture-handler" = "2.9.0"
  $pkg.dependencies."react-native-reanimated" = "3.4.2"
  $pkg.dependencies."@react-navigation/native" = "6.1.17"
  $pkg.dependencies."@react-navigation/drawer" = "6.6.3"
  $pkg.dependencies."expo-status-bar" = "~3.0.7"

  if ($pkg.dependencies."expo-dev-client"){ $pkg.dependencies.PSObject.Properties.Remove("expo-dev-client"); Log "Removed expo-dev-client (dep)" }
  if ($pkg.devDependencies."expo-dev-client"){ $pkg.devDependencies.PSObject.Properties.Remove("expo-dev-client"); Log "Removed expo-dev-client (devDep)" }

  $pkg.devDependencies."react-test-renderer" = "18.2.0"
  $pkg.main = "expo-router/entry"
  $pkg.name = "fundmind"
  if ($pkg.PSObject.Properties.Name -contains "overrides"){ $pkg.PSObject.Properties.Remove("overrides") }

  ($pkg | ConvertTo-Json -Depth 20) | Set-Content -Path $pkgPath -Encoding UTF8
  Remove-BOM $pkgPath
  Log "package.json pinned for SDK49"

  # 3) Clean install (bez legacy flag — SDK49 ma spójny zestaw)
  if (Test-Path "$projectRoot\node_modules"){ Remove-Item -Recurse -Force "$projectRoot\node_modules" }
  if (Test-Path "$projectRoot\package-lock.json"){ Remove-Item -Force "$projectRoot\package-lock.json" }
  Log "npm install clean..."
  npm install
  if ($LASTEXITCODE -ne 0){ throw "npm install failed" }

  # 4) expo-updates dopasowane do SDK49 (wersję dobierze expo install)
  Log "expo install expo-updates (SDK49 mapping)"
  npx expo install expo-updates
  if ($LASTEXITCODE -ne 0){ throw "expo install expo-updates failed" }

  # 5) EAS login
  Log "Checking EAS login"
  npx eas-cli whoami
  if ($LASTEXITCODE -ne 0){
    npx eas-cli login
    if ($LASTEXITCODE -ne 0){ throw "eas login failed" }
  }

  # 6) Publish update (bez expo start; bundluje headless)
  Log "Publishing EAS Update to branch main"
  npx eas-cli update --branch main --message "FundMind SDK49 publish for Expo Go"
  if ($LASTEXITCODE -ne 0){ throw "eas update failed" }

  Log "Done. Wejdź na dashboard EAS -> Updates, zeskanuj QR w Expo Go (iPhone)."
}
catch {
  LogErr "Exception: $_"
  exit 1
}
