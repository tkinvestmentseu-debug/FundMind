# fundmind-publish-sdk49.ps1 — Publikacja update do Expo Go (SDK 49) BEZ lokalnego metro
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir     = "$projectRoot\logs"
$errorsLog   = "$logsDir\errors.log"
$logFile     = "$logsDir\publish-sdk49.log"

function Log($m){ $t=Get-Date -Format s; Write-Host "[Publish49] $m"; "$t [Info] $m" | Out-File $logFile -Encoding UTF8 -Append }
function Fail($m){ $t=Get-Date -Format s; Write-Host "[Publish49-Error] $m"; "$t [Error] $m" | Out-File $errorsLog -Encoding UTF8 -Append; exit 1 }

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

try {
  Set-Location $projectRoot
  Log "Start publish pipeline (SDK 49, Expo Go)"

  # 1) Sanity JSONy + SDK 49
  $appPath = Join-Path $projectRoot "app.json"
  $pkgPath = Join-Path $projectRoot "package.json"
  if (!(Test-Path $appPath)) { Fail "app.json not found" }
  if (!(Test-Path $pkgPath)) { Fail "package.json not found" }

  # usuwamy BOM
  @("app.json","package.json","babel.config.js","metro.config.js","tsconfig.json") | ForEach-Object { Remove-BOM (Join-Path $projectRoot $_) }

  # app.json -> SDK 49 + owner/slug + runtimeVersion
  $app = Get-Content $appPath -Raw | ConvertFrom-Json
  if (-not $app.expo){ $app | Add-Member -Name expo -MemberType NoteProperty -Value (@{}) }
  $app.expo.name = "FundMind"
  $app.expo.slug = "fundmind"
  $app.expo.owner = "tomasz77"
  $app.expo.sdkVersion = "49.0.0"
  $app.expo.runtimeVersion = @{ policy = "sdkVersion" }
  # nie tykamy extra.eas.projectId jeśli już jest – EAS sam to wykorzysta
  ($app | ConvertTo-Json -Depth 12) | Set-Content -Path $appPath -Encoding UTF8
  Log "app.json set to SDK 49"

  # package.json -> piny kompatybilne z SDK 49
  $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
  if (-not $pkg.dependencies){ $pkg | Add-Member -Name dependencies -MemberType NoteProperty -Value (@{}) }
  if (-not $pkg.devDependencies){ $pkg | Add-Member -Name devDependencies -MemberType NoteProperty -Value (@{}) }

  $pkg.dependencies.expo                             = "~49.0.21"
  $pkg.dependencies."expo-router"                    = "~3.4.8"
  $pkg.dependencies.react                            = "18.2.0"
  $pkg.dependencies."react-dom"                      = "18.2.0"
  $pkg.dependencies."react-native"                   = "0.72.10"
  $pkg.dependencies."react-native-screens"           = "3.27.0"
  $pkg.dependencies."react-native-safe-area-context" = "4.6.3"
  $pkg.dependencies."react-native-gesture-handler"   = "2.9.0"
  $pkg.dependencies."react-native-reanimated"        = "3.4.2"
  $pkg.dependencies."@react-navigation/native"       = "6.1.17"
  $pkg.dependencies."@react-navigation/drawer"       = "6.6.3"
  $pkg.dependencies."expo-status-bar"                = "~3.0.7"

  # usuń dev client (Expo Go ma działać)
  if ($pkg.dependencies.PSObject.Properties.Name -contains "expo-dev-client") { $pkg.dependencies.PSObject.Properties.Remove("expo-dev-client"); Log "Removed expo-dev-client dep" }
  if ($pkg.devDependencies.PSObject.Properties.Name -contains "expo-dev-client") { $pkg.devDependencies.PSObject.Properties.Remove("expo-dev-client"); Log "Removed expo-dev-client devDep" }

  $pkg.devDependencies."react-test-renderer" = "18.2.0"
  $pkg.main = "expo-router/entry"
  $pkg.name = "fundmind"
  # usuń overrides
  if ($pkg.PSObject.Properties.Name -contains "overrides") { $pkg.PSObject.Properties.Remove("overrides"); Log "Removed npm overrides" }

  ($pkg | ConvertTo-Json -Depth 20) | Set-Content -Path $pkgPath -Encoding UTF8
  Log "package.json pinned for SDK 49"

  # 2) Install clean
  if (Test-Path "$projectRoot\node_modules"){ Remove-Item -Recurse -Force "$projectRoot\node_modules" }
  if (Test-Path "$projectRoot\package-lock.json"){ Remove-Item -Force "$projectRoot\package-lock.json" }
  Log "npm install (clean)"
  npm install
  if ($LASTEXITCODE -ne 0) { Fail "npm install failed" }

  # 3) expo-updates zgodny z SDK 49 (nie startujemy metro!)
  Log "Installing expo-updates (SDK-matched)"
  npx expo install expo-updates
  if ($LASTEXITCODE -ne 0) { Fail "expo install expo-updates failed" }

  # 4) EAS login
  Log "Check EAS login"
  npx eas-cli whoami
  if ($LASTEXITCODE -ne 0) {
    npx eas-cli login
    if ($LASTEXITCODE -ne 0) { Fail "eas login failed" }
  } else { Log "Already logged in" }

  # 5) Publikacja update (bez metro dev server)
  Log "Publishing update to branch 'main' (Expo Go consumes it)"
  npx eas-cli update --branch main --message "FundMind SDK49 publish for Expo Go" --non-interactive
  if ($LASTEXITCODE -ne 0) { Fail "eas update failed" }

  # 6) Wydrukuj szybki link do dashboardu (QR do skanowania w Expo Go)
  $dash = "https://expo.dev/accounts/tomasz77/projects/fundmind/updates"
  Log "Open this on your phone or scan QR there: $dash"
  Write-Host "`n=== OPEN THIS LINK FOR QR (Expo Go) ===`n$dash`n====================================`n"
}
catch {
  Fail "Exception: $_"
}
