$ErrorActionPreference = "Stop"
$env:REACT_NATIVE_PACKAGER_HOSTNAME = (Get-Content ".packager-ip" -Raw).Trim()
Set-Location $PSScriptRoot

# Zabij typowe porty Metro/Expo (jeśli zajęte)
foreach($p in 8081,19000,19001,19002){
  $procs = Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue |
           Select-Object -ExpandProperty OwningProcess -Unique
  foreach($pid in $procs){ try { Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue } catch {} }
}

# Start na wymuszonym IP
npx expo start --clear --host lan --port 8081
