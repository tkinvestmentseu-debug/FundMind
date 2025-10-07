param()
$projectRoot = "D:\FundMind"
$calPath = Join-Path $projectRoot "app\calendar\index.tsx"

if (Test-Path $calPath) {
  $content = Get-Content $calPath -Raw -Encoding UTF8

  # usuń wszystkie istniejące linie z daysInMonth
  $content = $content -replace '(?ms)^\s*const\s+daysInMonth\s*=.*?\);\s*',''

  # wstaw poprawną wersję po const months
  $content = $content -replace '(const months = .*;)', "`$1`r`n  const daysInMonth = useMemo(() => dayjs(`${ymd.y}-${String(ymd.m).padStart(2, ''0'')}-01`).daysInMonth(), [ymd.y, ymd.m]);"

  $content | Set-Content -Encoding UTF8 $calPath
  Write-Host "[FIX] Rewritten daysInMonth block"
} else {
  Write-Host "[ERR] calendar/index.tsx not found"
  exit 1
}

Set-Location $projectRoot
npx expo start --clear --port 8081 --host lan
