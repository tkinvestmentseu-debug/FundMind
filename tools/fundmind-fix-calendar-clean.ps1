param()
$projectRoot = "D:\FundMind"
$calPath = Join-Path $projectRoot "app\calendar\index.tsx"

if (Test-Path $calPath) {
  $content = Get-Content $calPath -Raw
  if ($content -match '\$\{ymd\.y\}--01') {
    $fixed = $content -replace '\$\{ymd\.y\}--01', '${ymd.y}-${String(ymd.m).padStart(2, ''0'')}-01'
    $fixed | Set-Content -Encoding UTF8 $calPath
    Write-Host "[FIX] Patched app/calendar/index.tsx (daysInMonth)"
  } else {
    Write-Host "[OK] calendar/index.tsx already correct"
  }
} else {
  Write-Host "[ERR] calendar/index.tsx not found"
}

Set-Location $projectRoot
npx expo start --clear --port 8081 --host lan
