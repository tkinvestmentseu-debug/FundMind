# fundmind-publish.ps1
$projectRoot = "D:\FundMind"
$logsDir = "$projectRoot\logs"
$errorsLog = "$logsDir\errors.log"

function Log-Info($msg) {
  Write-Host "[Publish] $msg"
  $timestamp = Get-Date -Format s
  "$timestamp [Info] $msg" | Out-File "$logsDir\publish.log" -Encoding UTF8 -Append
}

function Log-Error($msg) {
  Write-Host "[Publish-Error] $msg"
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

  # Login if needed
  Log-Info "Checking Expo login..."
  npx expo whoami
  if ($LASTEXITCODE -ne 0) {
    Log-Info "Not logged in, running expo login..."
    npx expo login
  } else {
    Log-Info "Already logged in"
  }

  # Publish to Expo Cloud
  Log-Info "Publishing app..."
  npx expo publish
  if ($LASTEXITCODE -ne 0) { Log-Error "expo publish failed with ExitCode=$LASTEXITCODE"; exit 1 }

  Log-Info "Publish completed successfully."
}
catch {
  Log-Error "Exception: $_"
  exit 1
}
