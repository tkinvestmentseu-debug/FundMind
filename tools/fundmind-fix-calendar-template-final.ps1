param()
$projectRoot = "D:\FundMind"
$calPath = Join-Path $projectRoot "app\calendar\index.tsx"

if (Test-Path $calPath) {
  $lines = Get-Content $calPath
  $new = @()
  foreach ($line in $lines) {
    if ($line -match 'dayjs') {
      # wymieniamy na poprawną wersję
      $new += '  const daysInMonth = useMemo('
      $new += '    () => dayjs(`${ymd.y}-${String(ymd.m).padStart(2, ''0'')}-01`).daysInMonth(),'
      $new += '    [ymd.y, ymd.m]'
      $new += '  );'
    } else {
      $new += $line
    }
  }
  $new | Set-Content -Encoding UTF8 $calPath
  Write-Host "[FIX] Replaced daysInMonth definition with correct template string"
} else {
  Write-Host "[ERR] calendar/index.tsx not found"
  exit 1
}

Set-Location $projectRoot
npx expo start --clear --port 8081 --host lan
