param()

$log = 'D:\FundMind\logs\fix-v26-20250914-135923.log'

function Log($m) {
  $ts = Get-Date -Format "HH:mm:ss"
  Add-Content -Path $log -Value "[20250914-132330] $m"
}

Log "Start v26 (diagnostic + expo)"

# check for executables
$bins = @("git.exe","cmd.exe","adb.exe")
foreach ($b in $bins) {
  $found = $false
  foreach ($p in $env:PATH -split ";") {
    $f = Join-Path $p $b
    if (Test-Path $f) { $found = $true; break }
  }
  if ($found) { Log "$b FOUND" } else { Log "$b MISSING" }
}

# ensure no BOM in json
$files = @("D:\FundMind\package.json","D:\FundMind\app.json")
foreach ($f in $files) {
  if (Test-Path $f) {
    $bytes = [System.IO.File]::ReadAllBytes($f)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
      $clean = $bytes[3..($bytes.Length-1)]
      [System.IO.File]::WriteAllBytes($f,$clean)
      Log "Removed BOM (bytes) from $f"
    } else {
      Log "Ensured no BOM in $f"
    }
  }
}

# run expo start
try {
  Log "Run: npx expo start --tunnel"
  & cmd.exe /d /s /c "npx expo start --tunnel" *>&1 | Tee-Object -FilePath $log -Append
  Log "Exit code: $LASTEXITCODE"
} catch {
  Log "Expo failed: $_"
}

Log "Done v26"
Start-Process notepad.exe $log
