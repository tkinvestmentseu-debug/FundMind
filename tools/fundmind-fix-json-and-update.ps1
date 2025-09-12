# fundmind-fix-json-and-update.ps1 (Anti-Errors 36..39)

$projectRoot = "D:\FundMind"
$logsDir = "$projectRoot\logs"
$errorsLog = "$logsDir\errors.log"

function Log-Info($m){ $t=Get-Date -Format s; Write-Host "[FixJSON] $m"; "$t [Info] $m" | Out-File "$logsDir\update.log" -Encoding UTF8 -Append }
function Log-Error($m){ $t=Get-Date -Format s; Write-Host "[FixJSON-Error] $m"; "$t [AntiError] $m" | Out-File $errorsLog -Encoding UTF8 -Append }

# --- Helper: remove BOM from JSON files ---
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
  Log-Info "Start JSON sanity + update"

  # Step 1: Remove BOM from all configs (Anti-Error #36, #38)
  $jsonFiles = @("package.json","app.json","tsconfig.json","babel.config.js","metro.config.js")
  foreach ($f in $jsonFiles){ Remove-BOM (Join-Path $projectRoot $f) }

  # Step 2: Ensure app.json owner/slug/sdk + remove stale projectId (Anti-Error #37)
  $appJsonPath = Join-Path $projectRoot "app.json"
  if (Test-Path $appJsonPath){
    $app = Get-Content $appJsonPath -Raw | ConvertFrom-Json
    if (-not $app.expo){ $app | Add-Member -Name expo -MemberType NoteProperty -Value (@{}) }
    $app.expo.name = "FundMind"
    $app.expo.slug = "fundmind"
    $app.expo.owner = "tomasz77"
    $app.expo.sdkVersion = "50.0.0"
    $app.expo.runtimeVersion = @{ policy = "sdkVersion" }
    if ($app.expo.PSObject.Properties.Name -contains "extra"){
      if ($app.expo.extra.PSObject.Properties.Name -contains "eas"){
        $app.expo.extra.PSObject.Properties.Remove("eas")
        Log-Info "Removed stale extra.eas.projectId"
      }
    }
    ($app | ConvertTo-Json -Depth 10) | Set-Content -Path $appJsonPath -Encoding UTF8
    Log-Info "app.json sanitized"
  }

  # Step 3: Clean install
  if (Test-Path "$projectRoot\node_modules"){ Remove-Item -Recurse -Force "$projectRoot\node_modules" }
  if (Test-Path "$projectRoot\package-lock.json"){ Remove-Item -Force "$projectRoot\package-lock.json" }
  Log-Info "npm install clean"
  npm install --legacy-peer-deps
  if ($LASTEXITCODE -ne 0){ Log-Error "npm install failed"; exit 1 }

  # Step 4: Align with expo install
  Log-Info "expo install align"
  npx expo install expo-router @react-navigation/native @react-navigation/drawer react-native-safe-area-context react-native-screens
  if ($LASTEXITCODE -ne 0){ Log-Error "expo install failed"; exit 1 }

  # Step 5: Ensure EAS login + init
  Log-Info "Check EAS login"
  npx eas-cli whoami
  if ($LASTEXITCODE -ne 0){
    npx eas-cli login
    if ($LASTEXITCODE -ne 0){ Log-Error "eas login failed"; exit 1 }
  }
  if (!(Test-Path "$projectRoot\.eas")){
    Log-Info "Running eas init"
    npx eas-cli init --non-interactive
    if ($LASTEXITCODE -ne 0){ Log-Error "eas init failed"; exit 1 }
  }

  # Step 6: Publish update
  Log-Info "Publishing with eas update"
  npx eas-cli update --branch main --message "FundMind JSON fix and deps align"
  if ($LASTEXITCODE -ne 0){ Log-Error "eas update failed"; exit 1 }

  Log-Info "Completed successfully"
}
catch {
  Log-Error "Exception: $_"
  exit 1
}
