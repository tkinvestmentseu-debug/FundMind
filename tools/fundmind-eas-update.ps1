# fundmind-eas-update.ps1 (Anti-Errors 26..34 enforced)
$projectRoot = "D:\FundMind"
$logsDir = "$projectRoot\logs"
$errorsLog = "$logsDir\errors.log"

function Log-Info($m){ $t=Get-Date -Format s; Write-Host "[EAS] $m"; "$t [Info] $m" | Out-File "$logsDir\update.log" -Encoding UTF8 -Append }
function Log-Error($m){ $t=Get-Date -Format s; Write-Host "[EAS-Error] $m"; "$t [AntiError] $m" | Out-File $errorsLog -Encoding UTF8 -Append }

try {
  Set-Location $projectRoot
  Log-Info "Start EAS update flow"

  # Ensure app.json minimal
  $appJsonPath = Join-Path $projectRoot "app.json"
  $app = @{}
  if (Test-Path $appJsonPath) { $app = Get-Content $appJsonPath -Raw | ConvertFrom-Json } else { $app = @{ } }
  if (-not $app.expo) { $app | Add-Member -Name expo -MemberType NoteProperty -Value (@{}) }
  if (-not ($app.expo.PSObject.Properties.Name -contains "owner")) { $app.expo | Add-Member -NotePropertyName "owner" -NotePropertyValue "tomasz77" }
  $app.expo.name = "FundMind"
  $app.expo.slug = "fundmind"
  $app.expo.sdkVersion = "50.0.0"
  $app.expo.runtimeVersion = @{ policy = "sdkVersion" }
  ($app | ConvertTo-Json -Depth 10) | Set-Content -Path $appJsonPath -Encoding UTF8
  Log-Info "app.json ensured"

  # Install deps (Anti-Error #34: force legacy peer deps)
  Log-Info "Installing deps with legacy-peer-deps"
  npm install --legacy-peer-deps
  if ($LASTEXITCODE -ne 0) { Log-Error "npm install failed ExitCode=$LASTEXITCODE"; exit 1 }

  # Ensure expo-router correct version (~3.4.10)
  Log-Info "Ensuring expo-router version ~3.4.10"
  npm install expo-router@~3.4.10 --legacy-peer-deps
  if ($LASTEXITCODE -ne 0) { Log-Error "expo-router fix failed ExitCode=$LASTEXITCODE"; exit 1 }

  # EAS login
  Log-Info "Checking EAS login"
  npx eas-cli whoami
  if ($LASTEXITCODE -ne 0) {
    Log-Info "Not logged in, running eas login..."
    npx eas-cli login
    if ($LASTEXITCODE -ne 0) { Log-Error "eas login failed ExitCode=$LASTEXITCODE"; exit 1 }
  } else { Log-Info "Already logged in" }

  # EAS init
  $easDir = Join-Path $projectRoot ".eas"
  if (!(Test-Path $easDir)) {
    Log-Info "Running eas init (no --id, avoid Invalid UUID bug)"
    npx eas-cli init --non-interactive
    if ($LASTEXITCODE -ne 0) { Log-Error "eas init failed ExitCode=$LASTEXITCODE"; exit 1 }
  } else { Log-Info "EAS project already linked" }

  # Publish update
  Log-Info "Publishing with eas update"
  npx eas-cli update --branch main --message "FundMind auto update"
  if ($LASTEXITCODE -ne 0) { Log-Error "eas update failed ExitCode=$LASTEXITCODE"; exit 1 }

  Log-Info "EAS update completed successfully"
}
catch {
  Log-Error "Exception: $_"
  exit 1
}
