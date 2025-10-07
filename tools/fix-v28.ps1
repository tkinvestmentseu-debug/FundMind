param()
function Log([string]$m) {
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Add-Content -Path "D:\FundMind\logs\fix-v28-20250914-140843.log" -Value "[$ts] $m"
}
Log "[START v28]"

# check executables
$bins = @("git.exe","cmd.exe","adb.exe","node.exe","npx.cmd")
foreach ($b in $bins) {
  $found = $false
  foreach ($p in $env:PATH -split ";") {
    if ($p -and (Test-Path (Join-Path $p $b))) { $found = $true; break }
  }
  if ($found) { Log "$b FOUND" } else { Log "$b MISSING" }
}

# ensure no BOM
$files = @("D:\FundMind\package.json","D:\FundMind\app.json")
foreach ($f in $files) {
  if (Test-Path $f) {
    $bytes = [System.IO.File]::ReadAllBytes($f)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
      $clean = $bytes[3..($bytes.Length-1)]
      [System.IO.File]::WriteAllBytes($f,$clean)
      Log "Removed BOM from $f"
    } else {
      Log "Ensured no BOM in $f"
    }
  }
}

# expo start fallback
$modes = @("--tunnel","--lan","--localhost")
$success = $false
foreach ($m in $modes) {
  Log "Run: npx expo start $m"
  & cmd.exe /d /s /c "npx expo start $m" *>&1 | Tee-Object -FilePath "D:\FundMind\logs\fix-v28-20250914-140843.log" -Append
  $exit = $LASTEXITCODE
  Log "Exit code: $exit"
  if ($exit -eq 0) { $success = $true; break }
  else { Log "Expo failed in mode $m" }
}

if (-not $success) { Log "All expo start modes failed." }

Log "[END v28]"
Start-Process notepad.exe "D:\FundMind\logs\fix-v28-20250914-140843.log"
