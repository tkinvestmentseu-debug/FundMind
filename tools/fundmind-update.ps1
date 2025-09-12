# fundmind-update.ps1
$projectRoot = "D:\FundMind"
$logsDir = "$projectRoot\logs"
$errorsLog = "$logsDir\errors.log"

function Log-Info($msg) {
  Write-Host "[Update] $msg"
  $timestamp = Get-Date -Format s
  "$timestamp [Info] $msg" | Out-File "$logsDir\update.log" -Encoding UTF8 -Append
}

function Log-Error($msg) {
  Write-Host "[Update-Error] $msg"
  $timestamp = Get-Date -Format s
  "$timestamp [AntiError] $msg" | Out-File $errorsLog -Encoding UTF8 -Append
}

try {
  Set-Location $projectRoot

  # Ensure app.json exists
  $appJson = Join-Path $projectRoot "app.json"
  if (!(Test-Path $appJson)) {
    $appConfig = @{
      expo = @{
        name  = "FundMind"
        slug  = "fundmind"
        owner = "tomasz77"
        version = "1.0.0"
        sdkVersion = "50.0.0"
        platforms = @("ios","android","web")
      }
    } | ConvertTo-Json -Depth 5
    Set-Content -Path $appJson -Value $appConfig -Encoding UTF8
    Log-Info "Created app.json"
  } else {
    Log-Info "app.json already exists"
  }

  # Initialize EAS
  Log-Info "Running eas init..."
  npx eas-cli init --non-interactive --id fundmind
  if ($LASTEXITCODE -ne 0) { Log-Error "eas init failed with ExitCode=$LASTEXITCODE"; exit 1 }

  # Publish update
  Log-Info "Publishing update..."
  npx eas-cli update --branch main --message "first publish"
  if ($LASTEXITCODE -ne 0) { Log-Error "eas update failed with ExitCode=$LASTEXITCODE"; exit 1 }

  Log-Info "EAS update completed successfully."
}
catch {
  Log-Error "Exception: $_"
  exit 1
}
