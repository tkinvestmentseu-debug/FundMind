param()
$projectRoot = "D:\FundMind"
$calPath = Join-Path $projectRoot "app\calendar\index.tsx"

if (Test-Path $calPath) {
  $content = Get-Content $calPath -Raw
  if ($content -match 'dayjs\(\$\{ymd\.y\}-') {
    $fixed = $content -replace 'dayjs\(\$\{ymd\.y\}-.*-01\)', 'dayjs(`${ymd.y}-${String(ymd.m).padStart(2, ''0'')}-01`)'
    $fixed | Set-Content -Encoding UTF8 $calPath
    Write-Host "[FIX] Patched app/calendar/index.tsx (daysInMonth with template string)"
  } else {
    Write-Host "[OK] Pattern not found or already fixed"
  }
} else {
  Write-Host "[ERR] calendar/index.tsx not found"
}

Set-Location $projectRoot
npx expo start --clear --port 8081 --host lan
