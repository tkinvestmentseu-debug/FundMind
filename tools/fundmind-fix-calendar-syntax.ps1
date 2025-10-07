param()
$projectRoot = "D:\FundMind"
$logsDir = Join-Path $projectRoot "logs"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logsDir "calendar-fix-$timestamp.log"
function Log($m){("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $m) | Tee-Object -FilePath $logFile -Append}

Set-Location $projectRoot
$calPath = Join-Path $projectRoot "app\calendar\index.tsx"

if (Test-Path $calPath) {
  $content = Get-Content $calPath -Raw
  if ($content -match '\$\{ymd\.y\}--01') {
    $fixed = $content -replace '\$\{ymd\.y\}--01', '${ymd.y}-${String(ymd.m).padStart(2, ''0'')}-01'
    $fixed | Set-Content -Encoding UTF8 $calPath
    Log "Patched app/calendar/index.tsx (fixed daysInMonth)"
  } else {
    Log "No buggy pattern found in app/calendar/index.tsx"
  }
} else {
  Log "ERROR: calendar/index.tsx not found"
}

# restart expo
Log "Starting Expo..."
npx expo start --clear --port 8081 --host lan 2>&1 | Tee-Object -FilePath $logFile -Append
