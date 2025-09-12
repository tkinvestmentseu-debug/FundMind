# fm-analyze-and-fix.ps1
$ErrorActionPreference = "Stop"
$projectRoot = Split-Path $PSScriptRoot -Parent
$logsDir  = Join-Path $projectRoot "logs"
$summary  = Join-Path $logsDir ("fix-summary-{0}.txt" -f (Get-Date -Format yyyyMMdd_HHmmss))
function Say($m){ Write-Host "[Fix] $m"; $m | Out-File $summary -Encoding UTF8 -Append }

Set-Location $projectRoot

# 1) Zbierz ostatnie logi
$latest = Get-ChildItem $logsDir -File | Sort-Object LastWriteTime -Descending | Select-Object -First 12
$logsText = ""
foreach($f in $latest){ $logsText += "`n--- $($f.Name) ---`n" + (Get-Content $f.FullName -Raw) }

Say "Analyzing recent logs..."
$found = @{}
function Hit($name,$pattern){ if ($logsText -match $pattern){ $found[$name]=$true; Say "Detected: $name" } }

# 2) Wzorce
Hit "BOM_JSON"        "Unexpected token|is not valid JSON|BOM"
Hit "ENOENT_SPAWN"    "ENOENT|System nie mo.?e odnale.|notFoundError"
Hit "ERESOLVE"        "npm error ERESOLVE|unable to resolve dependency tree|could not resolve"
Hit "EOVERRIDE"       "code EOVERRIDE|Override .* conflicts"
Hit "ROUTER_SDK49"    "EXPO_ROUTER_APP_ROOT|require\.context .* should be a string"
Hit "ROUTER_SDK50+"   "expo-router/babel is deprecated"
Hit "INVALID_UUID"    "Invalid UUID appId|GraphQL request failed"
Hit "EXPORT_FAIL"     "Export failed|cli export .* exited with non-zero code"
Hit "TIMEOUT_8081"    "ETIMEDOUT .*8081"

# utils: zapisz UTF-8 bez BOM (dla JSONów)
Add-Type -AssemblyName "System.Core" | Out-Null
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
function Write-Utf8NoBom([string]$path,[string]$text){ [System.IO.File]::WriteAllText($path,$text,$Utf8NoBom) }
function Strip-BOM([string]$path){ if(Test-Path $path){ $raw=Get-Content $path -Raw -Encoding Byte; if($raw.Length -ge 3 -and $raw[0]-eq 239 -and $raw[1]-eq 187 -and $raw[2]-eq 191){ [IO.File]::WriteAllBytes($path,$raw[3..($raw.Length-1)]); Say "BOM removed: $(Split-Path $path -Leaf)" } } }

# 3a) Usuń BOM z krytycznych plików
if ($found["BOM_JSON"]){
  foreach($p in @("package.json","app.json","babel.config.js","metro.config.js","tsconfig.json")){ Strip-BOM (Join-Path $projectRoot $p) }
  foreach($p in @("package.json","app.json")){ try{ Get-Content (Join-Path $projectRoot $p) -Raw | ConvertFrom-Json | Out-Null } catch{ Say "JSON invalid after BOM strip: $p => $($_.Exception.Message)" } }
}

# 3b) Dopasuj babel do SDK
function WriteBabel($withRouter){
  $b = if($withRouter){
    'module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["expo-router/babel","react-native-reanimated/plugin"] }; };'
  } else {
    'module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["react-native-reanimated/plugin"] }; };'
  }
  Set-Content -Path (Join-Path $projectRoot "babel.config.js") -Value $b -Encoding UTF8
  Say ("babel.config.js set " + ($(if($withRouter){"(with expo-router/babel)"} else {"(without expo-router/babel)"})))
}
$sdk = $null
try{ $app = Get-Content (Join-Path $projectRoot "app.json") -Raw | ConvertFrom-Json; if($app.expo -and $app.expo.sdkVersion){ $sdk=$app.expo.sdkVersion } }catch{}
if ($found["ROUTER_SDK49"] -and $sdk -like "49.*"){ WriteBabel $true }
if ($found["ROUTER_SDK50+"] -or ($sdk -and $sdk -notlike "49.*")){ WriteBabel $false }

# 3c) Usuń overrides (EOVERRIDE)
if ($found["EOVERRIDE"]){
  $pkgPath = Join-Path $projectRoot "package.json"
  $pkg = Get-Content $pkgPath -Raw | ConvertFrom-Json
  if ($pkg.PSObject.Properties.Name -contains "overrides"){
    $pkg.PSObject.Properties.Remove("overrides")
    Write-Utf8NoBom $pkgPath ($pkg | ConvertTo-Json -Depth 30)
    Say "Removed npm overrides"
  }
}

# 3d) ERESOLVE → clean install z legacy peer deps
if ($found["ERESOLVE"]){
  $env:npm_config_legacy_peer_deps = "true"
  if (Test-Path "$projectRoot\node_modules"){ Remove-Item -Recurse -Force "$projectRoot\node_modules" }
  if (Test-Path "$projectRoot\package-lock.json"){ Remove-Item -Force "$projectRoot\package-lock.json" }
  Say "Running npm install (legacy peer deps)"
  & cmd.exe /c "npm install --loglevel=warn > `"$logsDir\npm-install-fix.log`" 2>&1"
  Say "npm install finished (see npm-install-fix.log)"
}

# 3e) ENOENT → COMSPEC + PATH
if ($found["ENOENT_SPAWN"]){
  $env:COMSPEC = "$env:SystemRoot\System32\cmd.exe"
  $gitBin = "C:\Program Files\Git\bin"
  $nodePath = (Get-Command node.exe -ErrorAction SilentlyContinue)
  $npmPath  = (Get-Command npm.cmd  -ErrorAction SilentlyContinue)
  $paths = @()
  if ($nodePath) { $paths += (Split-Path $nodePath.Source) }
  if ($npmPath)  { $paths += (Split-Path $npmPath.Source) }
  $paths += $gitBin
  $paths += $env:PATH
  $env:PATH = ($paths -join ";")
  Say "COMSPEC/PATH adjusted for spawns"
}

# 3f) Invalid UUID → dołóż projectId
if ($found["INVALID_UUID"]){
  try{
    $appPath = Join-Path $projectRoot "app.json"
    $app = Get-Content $appPath -Raw | ConvertFrom-Json
    if (-not $app.expo.extra){ $app.expo | Add-Member -Name extra -MemberType NoteProperty -Value (@{}) }
    if (-not $app.expo.extra.eas){ $app.expo.extra | Add-Member -Name eas -MemberType NoteProperty -Value (@{}) }
    if (-not ($app.expo.extra.eas.PSObject.Properties.Name -contains "projectId")){
      $app.expo.extra.eas | Add-Member -Name projectId -MemberType NoteProperty -Value "ec364355-5e9f-4791-927f-f5fec18fbbde"
      Write-Utf8NoBom $appPath ($app | ConvertTo-Json -Depth 30)
      Say "Injected EAS projectId into app.json"
    }
  }catch{ Say "EAS fix failed: $($_.Exception.Message)" }
}

# 4) (opcjonalnie) align + EAS Update
try{
  Say "expo install align..."
  & cmd.exe /c "npx expo install > `"$logsDir\expo-install-fix.log`" 2>&1"
  Say "eas update publish..."
  & cmd.exe /c "npx eas-cli update --branch main --message `"auto-fix publish`" --non-interactive > `"$logsDir\eas-update-fix.log`" 2>&1"
  Say "Done. See logs\eas-update-fix.log"
}catch{
  Say "Publish step skipped: $($_.Exception.Message)"
}

Write-Host ""
Write-Host "=== FIX SUMMARY ==="
Get-Content $summary
