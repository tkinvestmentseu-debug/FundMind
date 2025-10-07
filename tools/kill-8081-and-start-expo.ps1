Write-Host "== Kill process on port 8081 if exists =="

try {
  $pid = (Get-NetTCPConnection -LocalPort 8081 -ErrorAction SilentlyContinue).OwningProcess
  if ($pid) {
    Write-Host "Found PID $pid using port 8081. Killing..."
    Stop-Process -Id $pid -Force
    Start-Sleep -Seconds 2
    Write-Host "Process $pid killed."
  } else {
    Write-Host "No process on port 8081."
  }
} catch {
  Write-Warning "Could not check/kill process on port 8081: $_"
}

Write-Host "== Start Expo on port 8081 with clear cache =="
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$logOut = Join-Path "D:\FundMind\logs" "expo-start-$ts.out.log"
$logErr = Join-Path "D:\FundMind\logs" "expo-start-$ts.err.log"

Start-Process -FilePath "npx" `
  -ArgumentList "expo start --clear --port 8081" `
  -WorkingDirectory "D:\FundMind" `
  -RedirectStandardOutput $logOut `
  -RedirectStandardError $logErr `
  -NoNewWindow
Write-Host "Expo starting... logs: $logOut , $logErr"
