# fix-anti-error-26.ps1
# Naprawa konfliktu React 19.x vs Expo SDK 50 (wymuszenie React 18.2.0 stack)

$projectRoot = "D:\FundMind"
$logsDir = "$projectRoot\logs"
$errorsLog = "$logsDir\errors.log"

function Log-Info($msg) {
  Write-Host "[Fix-26] $msg"
  $timestamp = Get-Date -Format s
  "$timestamp [Info] $msg" | Out-File "$logsDir\fix-26.log" -Encoding UTF8 -Append
}

function Log-Error($msg) {
  Write-Host "[Fix-26-Error] $msg"
  $timestamp = Get-Date -Format s
  "$timestamp [AntiError] $msg" | Out-File $errorsLog -Encoding UTF8 -Append
}

try {
  Set-Location $projectRoot
  Log-Info "Removing node_modules and package-lock..."
  if (Test-Path "$projectRoot\node_modules") { Remove-Item -Recurse -Force "$projectRoot\node_modules" }
  if (Test-Path "$projectRoot\package-lock.json") { Remove-Item -Force "$projectRoot\package-lock.json" }

  Log-Info "Installing fixed React stack..."
  npm install react@18.2.0 react-dom@18.2.0 react-test-renderer@18.2.0 react-native@0.73.6 --save-exact
  if ($LASTEXITCODE -ne 0) { Log-Error "npm install React stack failed with ExitCode=$LASTEXITCODE"; exit 1 }

  Log-Info "Reinstalling all deps..."
  npm install
  if ($LASTEXITCODE -ne 0) { Log-Error "npm install failed with ExitCode=$LASTEXITCODE"; exit 1 }

  Log-Info "Fix Anti-Error #26 completed successfully."
}
catch {
  Log-Error "Exception: $_"
  exit 1
}
