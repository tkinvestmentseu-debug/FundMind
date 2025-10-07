param()
function Log($m) {
  $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  Add-Content -Path $log -Value "[$ts] $m"
}
Log "[START v27]"

# Check for critical executables
$bins = @("git.exe","cmd.exe","adb.exe","node.exe","npx.cmd")
foreach ($b in $bins) {
  $found = $false
  foreach ($p in $env:PATH -split ";") {
    if ($p -and (Test-Path (Join-Path $p $b))) { $found = $true; break }
  }
  if ($found) { Log "$b FOUND" } else { Log "$b MISSING" }
}

# Ensure no BOM in JSON files
$files = @("$projectRoot\package.json","$projectRoot\app.json")
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

# Try expo start with fallback modes
$modes = @("--tunnel","--lan","--localhost")
$success = $false
foreach ($m in $modes) {
  Log "Run: npx expo start $m"
  & cmd.exe /d /s /c "npx expo start $m" *>&1 | Tee-Object -FilePath $log -Append
  $exit = $LASTEXITCODE
  Log "Exit code: $exit"
  if ($exit -eq 0) { $success = $true; break }
  else { Log "Expo failed in mode $m" }
}

if (-not $success) {
  Log "All expo start modes failed."
}

Log "[END v27]"
Start-Process notepad.exe $log
