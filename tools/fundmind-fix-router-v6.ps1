$ErrorActionPreference = "Stop"
$root = "D:\FundMind"
$logs = Join-Path $root "logs"; New-Item -ItemType Directory -Force -Path $logs | Out-Null
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$log = Join-Path $logs "fix-router-v6-$ts.log"
function LOG($m){ $m | Tee-Object -FilePath $log -Append }
function RUN([string]$cmd){ LOG ">>> $cmd"; cmd /c $cmd | Tee-Object -FilePath $log -Append }

Push-Location $root
try{
  LOG "=== FIX ROUTER V6: align deps, regenerate types, start expo ==="

  # 0) Kill Metro :8081
  LOG "Killing :8081..."
  $pids = (netstat -ano | findstr ":8081" | ForEach-Object { ($_ -split "\s+")[-1] } | Select-Object -Unique) 2>$null
  foreach($pid in $pids){ try{ Stop-Process -Id $pid -Force -ErrorAction SilentlyContinue } catch{} }

  # 1) Install compatible expo-router (~6.0.8)
  LOG "Installing expo-router@~6.0.8 (compat)..."
  RUN "npx expo install expo-router@~6.0.8"

  # 2) Disable temporary type overrides (if present)
  $typesOverride = Join-Path $root "types\expo-router-override.d.ts"
  if(Test-Path $typesOverride){
    LOG "Disabling override types: $typesOverride"
    Rename-Item $typesOverride "$($typesOverride).bak.$ts" -Force
  }

  # 3) Regenerate router types
  LOG "Running expo-router typegen..."
  $cli = Join-Path $root "node_modules\expo-router\build\bin\cli.js"
  if(Test-Path $cli){
    RUN "node `"$cli`" typegen"
  } else {
    RUN "npx expo-router typegen"
  }

  # 4) Typecheck
  LOG "Typecheck..."
  RUN "npm run typecheck"

  # 5) Start Expo with clean cache
  LOG "Starting Expo (clear cache)..."
  RUN "npx expo start -c"

  LOG "DONE ✅  (log: $log)"
}
catch{
  LOG "ERROR: $_"
}
finally{
  Pop-Location
  LOG "=== FIX ROUTER V6 DONE ==="
}
