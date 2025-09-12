# fm-expo-go-start-v6.ps1
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir  = Join-Path $projectRoot "logs"
$antiErr = Join-Path $logsDir "antierrors.log"
function Log($m){ $t=Get-Date -Format s; Write-Host "[ExpoGoStart] $m"; "$t [Info] $m" | Out-File (Join-Path $logsDir "expo-start-summary.log") -Append -Encoding UTF8 }
function Save-AE($code,$msg){ $t=Get-Date -Format s; "$t [$code] $msg" | Out-File $antiErr -Append -Encoding UTF8 }
function Write-Utf8NoBom($path,$text){ $enc = New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllText($path,$text,$enc) }
function Read-JsonSafe($path){ if(!(Test-Path $path)){ throw "$path not found" } $bytes=[IO.File]::ReadAllBytes($path); if($bytes.Length -ge 3 -and $bytes[0]-eq 239 -and $bytes[1]-eq 187 -and $bytes[2]-eq 191){ Save-AE "AE-56 JSON_BOM_REWRITE" ("BOM in " + (Split-Path $path -Leaf)); $bytes=$bytes[3..($bytes.Length-1)]; [IO.File]::WriteAllBytes($path,$bytes) } $text=[Text.Encoding]::UTF8.GetString($bytes); try{ return ($text|ConvertFrom-Json) } catch { Save-AE "AE-49-JSON" ("invalid JSON " + (Split-Path $path -Leaf) + ": " + $_.Exception.Message); throw } }
function Save-JsonNoBom($path,$obj){ $json=$obj|ConvertTo-Json -Depth 50; Write-Utf8NoBom $path $json }
function Ensure-Babel-ForSDK($sdk){ $babelFile=Join-Path $projectRoot "babel.config.js"; if($sdk -like "49.*"){ $c='module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["expo-router/babel","react-native-reanimated/plugin"] }; };'; Write-Utf8NoBom $babelFile $c; Log "babel.config.js -> SDK49 (WITH expo-router/babel)"; return "--tunnel -c --force-manifest-type=classic" } else { $c='module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["react-native-reanimated/plugin"] }; };'; Write-Utf8NoBom $babelFile $c; Log "babel.config.js -> SDK50+ (NO expo-router/babel)"; return "--tunnel -c" } }
function Ensure-ExpoInstalled($sdk){ $pkgPath=Join-Path $projectRoot "package.json"; $pkg=Read-JsonSafe $pkgPath; if(-not $pkg.dependencies){ $pkg | Add-Member -Name dependencies -MemberType NoteProperty -Value (@{}) } $desired= if($sdk -like "49.*"){ "~49.0.21" } elseif($sdk -like "50.*"){ "~50.0.0" } else { "~50.0.0" }; if(-not ($pkg.dependencies.PSObject.Properties.Name -contains "expo") -or $pkg.dependencies.expo -notlike $desired){ $pkg.dependencies.expo=$desired; Save-JsonNoBom $pkgPath $pkg; Log ("Pinned expo " + $desired + " (AE-55 SDK_MISMATCH)") } $expoDir=Join-Path $projectRoot "node_modules\expo"; if(!(Test-Path $expoDir)){ if(Test-Path (Join-Path $projectRoot "node_modules")){ Remove-Item -Recurse -Force (Join-Path $projectRoot "node_modules") } if(Test-Path (Join-Path $projectRoot "package-lock.json")){ Remove-Item -Force (Join-Path $projectRoot "package-lock.json") } Log "npm install (legacy-peer-deps) — installing expo locally"; npm install --legacy-peer-deps; if($LASTEXITCODE -ne 0){ Save-AE "AE-53 NPM_INSTALL_FAILED" ("npm install exit " + $LASTEXITCODE); throw "npm install failed ($LASTEXITCODE)" } } }
function Append-Path([string[]]$parts){ $uniq = @(); foreach($p in $parts){ if($p -and (Test-Path $p) -and -not ($env:PATH -split ";" | Where-Object { $_ -ieq $p })) { $uniq += $p } }; if($uniq.Count -gt 0){ $env:PATH = (($uniq + ($env:PATH -split ";")) -join ";") } }

try{
  Set-Location $projectRoot
  foreach($f in @("package.json","app.json","tsconfig.json")){ $p=Join-Path $projectRoot $f; if(Test-Path $p){ try{ $tmp=Read-JsonSafe $p; Save-JsonNoBom $p $tmp } catch {} } }
  $app = Read-JsonSafe (Join-Path $projectRoot "app.json")
  $sdk = if($app.expo -and $app.expo.sdkVersion){ $app.expo.sdkVersion } else { "49.0.0" }
  $startArgs = Ensure-Babel-ForSDK $sdk
  $pkgPath = Join-Path $projectRoot "package.json"; if(Test-Path $pkgPath){ $pkg=Read-JsonSafe $pkgPath; if(-not ($pkg.PSObject.Properties.Name -contains "main") -or $pkg.main -ne "expo-router/entry"){ $pkg.main="expo-router/entry"; Save-JsonNoBom $pkgPath $pkg; Log "package.json: set main=expo-router/entry" } }
  $env:COMSPEC="$env:SystemRoot\System32\cmd.exe"
  Append-Path @("$env:SystemRoot\System32","$env:SystemRoot","$env:SystemRoot\System32\WindowsPowerShell\v1.0","$env:SystemRoot\System32\wbem","C:\Windows\System32\OpenSSH","C:\Program Files\Git\bin")
  if(-not (Get-Command wsl.exe -ErrorAction SilentlyContinue)){ $env:EXPO_NO_WSL="1"; Log "EXPO_NO_WSL=1" }
  $env:BROWSER="none"; $env:EXPO_NO_DOCTOR="1"; $env:npm_config_legacy_peer_deps="true"; $env:CI="1"
  Ensure-ExpoInstalled $sdk
  if(Test-Path ".\.expo"){ Remove-Item -Recurse -Force ".\.expo" }
  if(Test-Path ".\.expo-shared"){ Remove-Item -Recurse -Force ".\.expo-shared" }
  $cliCandidates = @(
    (Join-Path $projectRoot "node_modules\expo\bin\cli.js"),
    (Join-Path $projectRoot "node_modules\expo\build\bin\cli.cjs"),
    (Join-Path $projectRoot "node_modules\expo\build\bin\cli.js")
  )
  $cliJs = $cliCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
  $expoCmd = Join-Path $projectRoot "node_modules\.bin\expo.cmd"
  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
  $startLog = Join-Path $logsDir ("expo-start-{0}.log" -f $ts)
  "=== ENV SNAPSHOT ===" | Out-File $startLog -Encoding UTF8
  ("NODE=" + (Get-Command node).Source) | Out-File $startLog -Append
  ("NPM =" + (Get-Command npm).Source)  | Out-File $startLog -Append
  ("PATH=" + $env:PATH) | Out-File $startLog -Append
  "" | Out-File $startLog -Append
  if($cliJs){
    $cmdLine = 'node "{0}" start {1}' -f $cliJs, $startArgs
    Log ("Starting (cli.js): " + $cmdLine); Log ("Log file: " + $startLog)
    Save-AE "AE-59 SPAWN_TARGET" $cmdLine
    & cmd.exe /c $cmdLine *>&1 | Tee-Object -FilePath $startLog
  } elseif (Test-Path $expoCmd) {
    Save-AE "AE-52 CLI_NOT_FOUND" "fallback to .bin\expo.cmd"
    $cmdLine = '"{0}" start {1}' -f $expoCmd, $startArgs
    Log ("Starting (.bin\expo.cmd): " + $cmdLine); Log ("Log file: " + $startLog)
    Save-AE "AE-59 SPAWN_TARGET" $cmdLine
    & cmd.exe /c $cmdLine *>&1 | Tee-Object -FilePath $startLog
  } else {
    Save-AE "AE-52 CLI_NOT_FOUND" "fallback to npx expo"
    $cmdLine = 'npx expo start {0}' -f $startArgs
    Log ("Starting (npx expo): " + $cmdLine); Log ("Log file: " + $startLog)
    Save-AE "AE-59 SPAWN_TARGET" $cmdLine
    & cmd.exe /c $cmdLine *>&1 | Tee-Object -FilePath $startLog
  }
} catch {
  Save-AE "AE-54 START_FAILED" ($_.Exception.Message)
  Write-Host ("[ExpoGoStart-Error] " + $_.Exception.Message)
  exit 1
}
