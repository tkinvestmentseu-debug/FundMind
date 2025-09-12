# fundmind-dev-build.ps1
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
Set-Location $projectRoot

function Log($m){ Write-Host "[DevBuild] $m" }

try {
  Log "Sanity check app.json"
  $app = Get-Content app.json -Raw | ConvertFrom-Json
  $app.expo.sdkVersion = "50.0.0"
  $app.expo.runtimeVersion = @{ policy = "sdkVersion" }
  ($app | ConvertTo-Json -Depth 10) | Set-Content app.json -Encoding UTF8

  Log "Sanity check package.json"
  $pkg = Get-Content package.json -Raw | ConvertFrom-Json
  $pkg.dependencies.expo = "~50.0.0"
  $pkg.main = "expo-router/entry"
  ($pkg | ConvertTo-Json -Depth 20) | Set-Content package.json -Encoding UTF8

  Log "Clean install"
  if (Test-Path node_modules){ Remove-Item -Recurse -Force node_modules }
  if (Test-Path package-lock.json){ Remove-Item -Force package-lock.json }
  npm install --legacy-peer-deps
  if ($LASTEXITCODE -ne 0){ throw "npm install failed" }

  Log "Ensure EAS login"
  npx eas-cli whoami
  if ($LASTEXITCODE -ne 0){ npx eas-cli login }

  Log "Build iOS dev client (you need Xcode/TestFlight to install)"
  npx eas-cli build --platform ios --profile development

  Log "Start Metro with tunnel (for iPhone Expo Go test)"
  npx expo start --tunnel
}
catch {
  Write-Host "[DevBuild-Error] $_"
  exit 1
}
