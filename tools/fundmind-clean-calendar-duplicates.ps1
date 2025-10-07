param()
$projectRoot = "D:\FundMind"
$calPath = Join-Path $projectRoot "app\calendar\index.tsx"

if (Test-Path $calPath) {
  $content = Get-Content $calPath -Raw -Encoding UTF8
  # usuwamy wszystkie linie z daysInMonth
  $cleaned = $content -replace '(?ms)^\s*const\s+daysInMonth\s*=.*?\);\s*',''
  # dodajemy poprawny blok zaraz po months
  $cleaned = $cleaned -replace '(const months = .*;)', "`$1`r`n  const daysInMonth = useMemo(() => dayjs(`${ymd.y}-${String(ymd.m).padStart(2, '0')}-01`).daysInMonth(), [ymd.y, ymd.m]);"
  $cleaned | Set-Content -Encoding UTF8 $calPath
  Write-Host "[FIX] Removed duplicates and restored correct daysInMonth"
} else {
  Write-Host "[ERR] calendar/index.tsx not found"
  exit 1
}

Set-Location $projectRoot
npx expo start --clear --port 8081 --host lan
