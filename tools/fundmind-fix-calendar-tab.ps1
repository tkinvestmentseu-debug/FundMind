param()
$projectRoot = "D:\FundMind"
$tabsLayout = Join-Path $projectRoot "app\(tabs)\_layout.tsx"
$calPath = Join-Path $projectRoot "app\calendar\index.tsx"

if (-not (Test-Path $calPath)) {
  Write-Host "[ERR] app/calendar/index.tsx not found"
  exit 1
}

if (Test-Path $tabsLayout) {
  $content = Get-Content $tabsLayout -Raw
  if ($content -notmatch 'name="calendar"') {
    $patched = $content -replace '(<Tabs>)', "`$1`r`n      <Tabs.Screen name='calendar' options={{ title: 'Kalendarz' }} />"
    $patched | Set-Content -Encoding UTF8 $tabsLayout
    Write-Host "[FIX] Patched (tabs)/_layout.tsx with Calendar tab"
  } else {
    Write-Host "[OK] Calendar tab already present"
  }
} else {
  Write-Host "[ERR] (tabs)/_layout.tsx not found"
  exit 1
}

Set-Location $projectRoot
npx expo start --clear --port 8081 --host lan
