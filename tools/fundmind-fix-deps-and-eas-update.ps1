# fundmind-fix-deps-and-eas-update.ps1 (Anti-Errors 26..38)

$projectRoot = "D:\FundMind"
$logsDir = "$projectRoot\logs"
$errorsLog = "$logsDir\errors.log"

function Log-Info($m){ $t=Get-Date -Format s; Write-Host "[FixEAS] $m"; "$t [Info] $m" | Out-File "$logsDir\update.log" -Encoding UTF8 -Append }
function Log-Error($m){ $t=Get-Date -Format s; Write-Host "[FixEAS-Error] $m"; "$t [AntiError] $m" | Out-File $errorsLog -Encoding UTF8 -Append }

function Ensure-Prop($obj,$name,$value){
  if (-not ($obj.PSObject.Properties.Name -contains $name)){
    $obj | Add-Member -NotePropertyName $name -NotePropertyValue $value
  } else { $obj.$name = $value }
}

try {
  Set-Location $projectRoot
  Log-Info "Start fix deps and EAS update"

  # === Step 1: Fix package.json BOM (Anti-Error #36)
  $pkgPath = Join-Path $projectRoot "package.json"
  if (!(Test-Path $pkgPath)) { throw "package.json not found" }
  $raw = Get-Content $pkgPath -Raw -Encoding Byte
  # Remove BOM if exists
  if ($raw.Length -ge 3 -and $raw[0] -eq 239 -and $raw[1] -eq 187 -and $raw[2] -eq 191) {
    $clean = $raw[3..($raw.Length-1)]
    [IO.File]::WriteAllBytes($pkgPath,$clean)
    Log-Info "Removed BOM from package.json"
  }

  # === Step 2: Load JSON safely
  $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json

  if (-not $pkg.dependencies) { $pkg | Add-Member -Name dependencies -MemberType NoteProperty -Value (@{}) }
  if (-not $pkg.devDependencies) { $pkg | Add-Member -Name devDependencies -MemberType NoteProperty -Value (@{}) }

  function Ensure-Dep($deps,$k,$v){
    if (-not ($deps.PSObject.Properties.Name -contains $k)){
      $deps | Add-Member -NotePropertyName $k -NotePropertyValue $v
    } else { $deps.$k = $v }
  }

  # Pin SDK 50 stack
  Ensure-Dep $pkg.dependencies "expo" "~50.0.0"
  Ensure-Dep $pkg.dependencies "expo-router" "~3.4.10"
  Ensure-Dep $pkg.dependencies "react" "18.2.0"
  Ensure-Dep $pkg.dependencies "react-dom" "18.2.0"
  Ensure-Dep $pkg.dependencies "react-native" "0.73.6"
  Ensure-Dep $pkg.devDependencies "react-test-renderer" "18.2.0"

  ($pkg | ConvertTo-Json -Depth 20) | Set-Content -Path $pkgPath -Encoding UTF8
  Log-Info "package.json pinned and BOM-free"

  # === Step 3: Ensure app.json without stale projectId (Anti-Error #37)
  $appJsonPath = Join-Path $projectRoot "app.json"
  $app = Get-Content $appJsonPath -Raw | ConvertFrom-Json
  if (-not $app.expo) { $app | Add-Member -Name expo -MemberType NoteProperty -Value (@{}) }
  Ensure-Prop $app.expo "name" "FundMind"
  Ensure-Prop $app.expo "slug" "fundmind"
  Ensure-Prop $app.expo "owner" "tomasz77"
  Ensure-Prop $app.expo "sdkVersion" "50.0.0"
  if ($app.expo.PSObject.Properties.Name -contains "extra") {
    if ($app.expo.extra.PSObject.Properties.Name -contains "eas") {
      $app.expo.extra.PSObject.Properties.Remove("eas")
      Log-Info "Removed stale extra.eas.projectId"
    }
  }
  ($app | ConvertTo-Json -Depth 10) | Set-Content -Path $appJsonPath -Encoding UTF8

  # === Step 4: Clean install
  if (Test-Path "$projectRoot\node_modules") { Remove-Item -Recurse -Force "$projectRoot\node_modules" }
  if (Test-Path "$projectRoot\package-lock.json") { Remove-Item -Force "$projectRoot\package-lock.json" }
  Log-Info "npm install clean"
  npm install --legacy-peer-deps
  if ($LASTEXITCODE -ne 0) { Log-Error "npm install failed"; exit 1 }

  # === Step 5: Align with expo install
  Log-Info "expo install align"
  npx expo install expo-router @react-navigation/native @react-navigation/drawer react-native-safe-area-context react-native-screens
  if ($LASTEXITCODE -ne 0) { Log-Error "expo install failed"; exit 1 }

  # === Step 6: EAS login/init
  Log-Info "Check EAS login"
  npx eas-cli whoami
  if ($LASTEXITCODE -ne 0) {
    npx eas-cli login
    if ($LASTEXITCODE -ne 0) { Log-Error "eas login failed"; exit 1 }
  }

  $easDir = Join-Path $projectRoot ".eas"
  if (!(Test-Path $easDir)) {
    Log-Info "Running eas init"
    npx eas-cli init --non-interactive
    if ($LASTEXITCODE -ne 0) { Log-Error "eas init failed"; exit 1 }
  }

  # === Step 7: Publish
  Log-Info "Publishing update"
  npx eas-cli update --branch main --message "FundMind fixed deps and projectId"
  if ($LASTEXITCODE -ne 0) { Log-Error "eas update failed"; exit 1 }

  Log-Info "Completed successfully"
}
catch {
  Log-Error "Exception: $_"
  exit 1
}
