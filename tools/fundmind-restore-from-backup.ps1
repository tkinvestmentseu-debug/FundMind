param()
$projectRoot = "D:\FundMind"
$backupRoot  = "C:\Fundmind kopia zapasowa aktualna240925"
$logsDir     = Join-Path $projectRoot "logs"
$timestamp   = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile     = Join-Path $logsDir "restore-$timestamp.log"

function Log($msg) {
  $line = "[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $msg
  $line | Tee-Object -FilePath $logFile -Append
}

Log "=== Start restore from backup ==="

# clean project dir
if (Test-Path $projectRoot) {
  Get-ChildItem -Path $projectRoot -Force | ForEach-Object {
    if ($_.Name -ne "logs" -and $_.Name -ne "tools") {
      try {
        Remove-Item -Recurse -Force $_.FullName
        Log "Removed: $($_.FullName)"
      } catch {
        Log "Skip remove error: $($_.FullName) - $($_.Exception.Message)"
      }
    }
  }
}

# copy backup
if (!(Test-Path $backupRoot)) {
  Log "ERROR: Backup not found: $backupRoot"
  exit 1
}
Get-ChildItem -Path $backupRoot -Force | ForEach-Object {
  $dest = Join-Path $projectRoot $_.Name
  Copy-Item $_.FullName $dest -Recurse -Force
  Log "Restored: $($_.Name)"
}

# clean node_modules and lockfile just in case
foreach ($item in @("node_modules","package-lock.json")) {
  $path = Join-Path $projectRoot $item
  if (Test-Path $path) {
    Remove-Item -Recurse -Force $path
    Log "Removed leftover: $item"
  }
}

# reinstall deps
Set-Location $projectRoot
Log "Installing dependencies..."
npm install 2>&1 | Tee-Object -FilePath $logFile -Append
npx expo install 2>&1 | Tee-Object -FilePath $logFile -Append

# start expo
Log "Starting Expo on 192.168.0.16:8081..."
npx expo start --clear --port 8081 --host 192.168.0.16 2>&1 | Tee-Object -FilePath $logFile -Append
