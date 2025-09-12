# fm-metro-reset-and-start.ps1
$ErrorActionPreference="Stop"
$projectRoot="D:\FundMind"
$logsDir = Join-Path $projectRoot "logs"
$antiErr = Join-Path $logsDir "antierrors.log"
function Log($m){ $t=Get-Date -Format s; Write-Host "[MetroFix] $m"; "$t [Info] $m" | Out-File (Join-Path $logsDir "metro-fix-summary.log") -Append -Encoding UTF8 }
function AE($code,$msg){ $t=Get-Date -Format s; "$t [$code] $msg" | Out-File $antiErr -Append -Encoding UTF8 }
function Write-Utf8NoBom($path,$text){ $enc=New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllText($path,$text,$enc) }
function ReadJsonSafe($p){ $b=[IO.File]::ReadAllBytes($p); if($b.Length -ge 3 -and $b[0]-eq 239 -and $b[1]-eq 187 -and $b[2]-eq 191){ $b=$b[3..($b.Length-1)]; [IO.File]::WriteAllBytes($p,$b); AE "AE-56 JSON_BOM_REWRITE" ("BOM in "+(Split-Path $p -Leaf)) } ([Text.Encoding]::UTF8.GetString($b)) | ConvertFrom-Json }

try {
  Set-Location $projectRoot
  # 1) Hard reset metro.config.js (usuwa deep importy do metro-cache/src/...)
  $metroCfg = 'const { getDefaultConfig } = require("expo/metro-config"); const config = getDefaultConfig(__dirname); module.exports = config;'
  Write-Utf8NoBom (Join-Path $projectRoot "metro.config.js") $metroCfg
  Log "metro.config.js reset -> expo/metro-config"

  # 2) Usu? BOM-y z kluczowych plik?w
  foreach($f in @("package.json","app.json","babel.config.js","tsconfig.json")){
    $p=Join-Path $projectRoot $f; if(Test-Path $p){ try{ $null=ReadJsonSafe $p } catch { } }
  }

  # 3) Ustal SDK i ustaw babel
  $app = ReadJsonSafe (Join-Path $projectRoot "app.json")
  $sdk = if($app.expo -and $app.expo.sdkVersion){ $app.expo.sdkVersion } else { "50.0.0" }
  if($sdk -like "49.*"){
    $babel = 'module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["expo-router/babel","react-native-reanimated/plugin"] }; };'
    Write-Utf8NoBom (Join-Path $projectRoot "babel.config.js") $babel
    $args = @("--tunnel","-c","--force-manifest-type=classic")
    Log "babel.config.js -> SDK49"
  } else {
    $babel = 'module.exports = function(api){ api.cache(true); return { presets:["babel-preset-expo"], plugins:["react-native-reanimated/plugin"] }; };'
    Write-Utf8NoBom (Join-Path $projectRoot "babel.config.js") $babel
    $args = @("--tunnel","-c")
    Log "babel.config.js -> SDK50+"
  }

  # 4) Wyczy?? cache i zwolnij port 8081
  if(Test-Path ".\.expo"){ Remove-Item -Recurse -Force ".\.expo" }
  if(Test-Path ".\.expo-shared"){ Remove-Item -Recurse -Force ".\.expo-shared" }
  $lines = cmd.exe /c "netstat -ano | findstr :8081" 2>$null
  if($lines){ AE "AE-70 PORT_8081_BUSY" ($lines -join " | "); foreach($ln in $lines){ $p=$ln -split "\s+"; $pid=$p[$p.Length-1]; if($pid -match "^\d+$"){ try{ Stop-Process -Id [int]$pid -Force -ErrorAction SilentlyContinue } catch {} } } }

  # 5) Wyb?r CLI i start przez Start-Process (logi do plik?w)
  $cli1 = Join-Path $projectRoot "node_modules\expo\bin\cli.js"
  $cli2 = Join-Path $projectRoot "node_modules\@expo\cli\build\bin\cli.js"
  $expoCmd = Join-Path $projectRoot "node_modules\.bin\expo.cmd"
  $ts = Get-Date -Format "yyyyMMdd_HHmmss"
  $outLog = Join-Path $logsDir ("metro-start-{0}.out.log" -f $ts)
  $errLog = Join-Path $logsDir ("metro-start-{0}.err.log" -f $ts)

  if(Test-Path $cli1){
    $file="node"; $argList=@($cli1,"start") + $args
    AE "AE-59 SPAWN_TARGET" ("node "+($argList -join " "))
    Log ("Starting (cli1): node "+($argList -join " "))
    Start-Process -FilePath $file -ArgumentList $argList -NoNewWindow -RedirectStandardOutput $outLog -RedirectStandardError $errLog -Wait
  } elseif (Test-Path $cli2){
    $file="node"; $argList=@($cli2,"start") + $args
    AE "AE-59 SPAWN_TARGET" ("node "+($argList -join " "))
    Log ("Starting (cli2): node "+($argList -join " "))
    Start-Process -FilePath $file -ArgumentList $argList -NoNewWindow -RedirectStandardOutput $outLog -RedirectStandardError $errLog -Wait
  } elseif (Test-Path $expoCmd){
    $file=$expoCmd; $argList=@("start") + $args
    AE "AE-59 SPAWN_TARGET" ($expoCmd+" "+($argList -join " "))
    Log ("Starting (expo.cmd): "+$expoCmd+" "+($argList -join " "))
    Start-Process -FilePath $file -ArgumentList $argList -NoNewWindow -RedirectStandardOutput $outLog -RedirectStandardError $errLog -Wait
  } else {
    AE "AE-52 CLI_NOT_FOUND" "no local expo CLI; using npx"
    $file="npx"; $argList=@("expo","start") + $args
    Log ("Starting (npx): npx "+($argList -join " "))
    Start-Process -FilePath $file -ArgumentList $argList -NoNewWindow -RedirectStandardOutput $outLog -RedirectStandardError $errLog -Wait
  }

  # 6) Post-skan log?w: wykryj znane problemy
  $out = if(Test-Path $outLog){ Get-Content $outLog -Raw } else { "" }
  $err = if(Test-Path $errLog){ Get-Content $errLog -Raw } else { "" }
  $all = $out + "`n" + $err
  if($all -match "Package subpath .*FileStore.* not defined"){ AE "AE-93 METRO_CACHE_SUBPATH" "detected after start" }
  if($all -match "ENOENT|notFoundError|nie mo"){ AE "AE-73 CROSSSPAWN_NOTFOUND" "spawn path error in output" }

  # 7) Poka? ogon log?w i zako?cz
  Log ("Logs: " + $outLog + " | " + $errLog)
  Write-Host "`n--- tail(out) ---"
  if(Test-Path $outLog){ Get-Content $outLog -Tail 30 }
  Write-Host "`n--- tail(err) ---"
  if(Test-Path $errLog){ Get-Content $errLog -Tail 30 }
  Write-Host "`n=== DONE ==="
}
catch{ AE "AE-54 START_FAILED" $_.Exception.Message; Write-Host ("[MetroFix-Error] "+$_.Exception.Message); Write-Host "=== DONE (error) ==="; exit 1 }
