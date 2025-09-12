# fm-expo-go-live.ps1  —  AE: 49,50,53,55,56,70,80,82
$ErrorActionPreference = "Stop"

# --- paths / logs
$pr = "D:\FundMind"
$tools = Join-Path $pr "tools"
$logs  = Join-Path $pr "logs"
if (!(Test-Path $tools)) { New-Item -Type Directory -Force -Path $tools | Out-Null }
if (!(Test-Path $logs))  { New-Item -Type Directory -Force -Path $logs  | Out-Null }
$antiErr = Join-Path $logs "antierrors.log"

function Log($m){ $t=Get-Date -Format s; Write-Host "[Live] $m"; "$t [Info] $m" | Out-File (Join-Path $logs "live.log") -Append -Encoding UTF8 }
function AE($code,$m){ $t=Get-Date -Format s; "$t [$code] $m" | Out-File $antiErr -Append -Encoding UTF8 }
function W($p,$txt){ $enc=[Text.UTF8Encoding]::new($false); [IO.File]::WriteAllText($p,$txt,$enc) }
function DeBOM($p){ if(Test-Path $p){ $b=[IO.File]::ReadAllBytes($p); if($b.Length -ge 3 -and $b[0]-eq 239 -and $b[1]-eq 187 -and $b[2]-eq 191){ [IO.File]::WriteAllBytes($p,$b[3..($b.Length-1)]); Log "BOM fixed: $(Split-Path $p -Leaf)" } } }
function ReadJson($p){ $b=[IO.File]::ReadAllBytes($p); if($b.Length -ge 3 -and $b[0]-eq 239 -and $b[1]-eq 187 -and $b[2]-eq 191){ [IO.File]::WriteAllBytes($p,$b[3..($b.Length-1)]) }; ([Text.Encoding]::UTF8.GetString([IO.File]::ReadAllBytes($p))) | ConvertFrom-Json }

try{
  if(!(Test-Path $pr)){ throw "Project folder not found: $pr" }
  Set-Location $pr

  # 1) Minimalny metro.config + babel wg SDK
  DeBOM "$pr\app.json"
  $sdk = "50.0.0"
  try { $app = ReadJson "$pr\app.json"; if($app.expo -and $app.expo.sdkVersion){ $sdk = $app.expo.sdkVersion } }
  catch { AE "AE-49-JSON" $_.Exception.Message }

  $metroCfg = 'const { getDefaultConfig }=require("expo/metro-config"); const config=getDefaultConfig(__dirname); module.exports=config;'
  W "$pr\metro.config.js" $metroCfg
  if($sdk -like "49.*"){
    $babel = 'module.exports=function(api){api.cache(true);return{presets:["babel-preset-expo"],plugins:["expo-router/babel","react-native-reanimated/plugin"]};};'
    Log "babel -> SDK49"
  } else {
    $babel = 'module.exports=function(api){api.cache(true);return{presets:["babel-preset-expo"],plugins:["react-native-reanimated/plugin"]};};'
    Log "babel -> SDK50+"
  }
  W "$pr\babel.config.js" $babel

  # 2) Shim + łatki AE-80/AE-82
  $shimPath = Join-Path $tools "metro-filestore-shim.js"
  $shim = @(
    '/* tools/metro-filestore-shim.js */'
    'let FileStore=null;'
    'try{ const mc=require("metro-cache"); FileStore=mc.FileStore||null; }catch(e){}'
    'if(!FileStore){ try{ FileStore=require("metro-cache/build/stores/FileStore"); }catch(e){} }'
    'if(!FileStore){ throw new Error("AE-80: FileStore not available from metro-cache"); }'
    'module.exports=FileStore;'
  ) -join "`r`n"
  W $shimPath $shim
  Log "Shim zapisany: tools/metro-filestore-shim.js"

  function PatchExpoMetroConfig(){
    $targets = @(
      "$pr\node_modules\@expo\metro-config\build\file-store.js",
      "$pr\node_modules\@expo\metro-config\src\file-store.ts"
    )
    foreach($t in $targets){
      if(Test-Path $t){
        $txt  = Get-Content $t -Raw
        $repl = $txt -replace 'metro-cache\/(src|build)\/stores\/FileStore','../../../tools/metro-filestore-shim'
        if($repl -ne $txt){
          W $t $repl
          AE "AE-80" "patched $([IO.Path]::GetFileName($t))"
          Log "AE-80 patch: $t"
        }
      }
    }
  }

  function CreateMetroCacheFallback(){
    $mcSrcDir = "$pr\node_modules\metro-cache\src\stores"
    if(!(Test-Path $mcSrcDir)){ New-Item -Type Directory -Force -Path $mcSrcDir | Out-Null }
    $file = "$mcSrcDir\FileStore.js"
    $content = @(
      '// fallback for require("metro-cache/src/stores/FileStore")'
      'try{ module.exports = require("metro-cache").FileStore; }'
      'catch(e){ try{ module.exports = require("../../build/stores/FileStore"); }'
      'catch(e2){ throw e; } }'
    ) -join "`r`n"
    W $file $content
    AE "AE-82" "created metro-cache/src/stores/FileStore.js fallback"
    Log "Fallback: metro-cache/src/stores/FileStore.js"
  }

  # 3) Upewnij lokalny CLI; po install – ponownie patchuj
  $cliExpo = "$pr\node_modules\@expo\cli\build\bin\cli.js"
  $cliOld  = "$pr\node_modules\expo\bin\cli.js"
  $needInstall = -not (Test-Path $cliExpo) -and -not (Test-Path $cliOld)
  if($needInstall){
    Log "Brak lokalnego CLI – npm install (legacy-peer-deps)"
    if(Test-Path "$pr\node_modules"){ Remove-Item -Recurse -Force "$pr\node_modules" }
    if(Test-Path "$pr\package-lock.json"){ Remove-Item -Force "$pr\package-lock.json" }
    npm install --legacy-peer-deps
    if($LASTEXITCODE -ne 0){ AE "AE-53" "npm install exit $LASTEXITCODE"; throw "npm install failed ($LASTEXITCODE)" }
  }

  # 4) Patch zawsze po (możliwym) npm install
  PatchExpoMetroConfig
  CreateMetroCacheFallback

  # 5) Porządek + port 8081
  foreach($f in 'package.json','app.json','metro.config.js','babel.config.js'){ DeBOM (Join-Path $pr $f) }
  if(Test-Path ".\.expo"){ Remove-Item -Recurse -Force ".\.expo" }
  if(Test-Path ".\.expo-shared"){ Remove-Item -Recurse -Force ".\.expo-shared" }
  $net = cmd.exe /c 'netstat -ano | findstr :8081' 2>$null
  if($net){ AE "AE-70" ($net -join " | "); foreach($ln in $net){ $p=$ln -split '\s+'; $pid=$p[$p.Length-1]; if($pid -match '^\d+$'){ try{ Stop-Process -Id ([int]$pid) -Force -ErrorAction SilentlyContinue }catch{} } } }

  # 6) Start – zostaje w tej konsoli
  $args = @('--tunnel','-c')
  if(Test-Path $cliExpo){ Log ("run: node $cliExpo start "+($args -join ' ')); & node $cliExpo start @args; return }
  if(Test-Path $cliOld ){ Log ("run: node $cliOld start "+($args -join ' '));  & node $cliOld  start @args; return }
  $expoCmd = "$pr\node_modules\.bin\expo.cmd"
  if(Test-Path $expoCmd){ Log ("run: $expoCmd start "+($args -join ' ')); & $expoCmd start @args; return }
  AE "AE-52" "CLI_NOT_FOUND fallback to npx"
  Log ("run: npx expo start "+($args -join ' '))
  & npx expo start @args
}
catch{
  AE "AE-54" $_.Exception.Message
  Write-Host "[Live-Error] $($_.Exception.Message)"
  exit 1
}