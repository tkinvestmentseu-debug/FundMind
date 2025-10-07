param()
function Log([string]$m) {
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Add-Content -Path "D:\FundMind\logs\fix-v29-20250914-142328.log" -Value "[$ts] $m"
}
Log "[START v29]"

# check executables
$bins = @("node.exe","npx.cmd")
foreach ($b in $bins) {
  $found = $false
  foreach ($p in $env:PATH -split ";") {
    if ($p -and (Test-Path (Join-Path $p $b))) { $found = $true; break }
  }
  if ($found) { Log "$b FOUND" } else { Log "$b MISSING" }
}

# update babel-preset-expo
try {
  Log "Run: npm install babel-preset-expo@^10.0.0 --save-dev"
  & cmd.exe /d /s /c "npm install babel-preset-expo@^10.0.0 --save-dev" *>&1 | Tee-Object -FilePath "D:\FundMind\logs\fix-v29-20250914-142328.log" -Append
  Log "Exit code: $LASTEXITCODE"
} catch {
  Log "npm install failed: $_"
}

# expo start
try {
  Log "Run: npx expo start --localhost"
  & cmd.exe /d /s /c "npx expo start --localhost" *>&1 | Tee-Object -FilePath "D:\FundMind\logs\fix-v29-20250914-142328.log" -Append
  Log "Exit code: $LASTEXITCODE"
} catch {
  Log "expo start failed: $_"
}

Log "[END v29]"
Start-Process notepad.exe "D:\FundMind\logs\fix-v29-20250914-142328.log"
