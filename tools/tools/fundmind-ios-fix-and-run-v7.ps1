Param()
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir = Join-Path $projectRoot "logs"
if(-not (Test-Path $logsDir)){ New-Item -ItemType Directory -Force -Path $logsDir | Out-Null }
$ts = (Get-Date).ToString("yyyyMMdd-HHmmss")
$log = Join-Path $logsDir ("fundmind-ios-" + $ts + ".log")
function Log($m){ $line = "[" + (Get-Date).ToString("HH:mm:ss") + "] " + $m; Write-Host $line; Add-Content -Path $log -Value $line -Encoding UTF8 }
function HasProp($o,$n){ if($null -eq $o){ return $false }; return $o.PSObject.Properties.Name -contains $n }
function Ensure-Prop($o,[string]$n,$v){ if(-not (HasProp $o $n)){ $o | Add-Member -NotePropertyName $n -NotePropertyValue $v } else { $o.$n = $v } }
function Remove-Prop($o,[string]$n){ if(HasProp $o $n){ [void]$o.PSObject.Properties.Remove($n) } }
function Invoke-CmdLine([string]$cmd){
  Log ("Run: " + $cmd)
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = "cmd.exe"
  $psi.Arguments = "/d /s /c " + $cmd
  $psi.WorkingDirectory = $projectRoot
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.CreateNoWindow = $true
  $proc = [System.Diagnostics.Process]::Start($psi)
  $stdout = $proc.StandardOutput.ReadToEnd()
  $stderr = $proc.StandardError.ReadToEnd()
  $proc.WaitForExit()
  if($stdout){ Add-Content -Path $log -Value $stdout -Encoding UTF8 }
  if($stderr){ Add-Content -Path $log -Value $stderr -Encoding UTF8 }
  if($proc.ExitCode -ne 0){ throw ("Command failed (" + $cmd + ") exit " + $proc.ExitCode) }
  else { Log ("OK: " + $cmd) }
}
Log "Start v7"
Set-Location $projectRoot
# package.json enforce versions
$pkgPath = Join-Path $projectRoot "package.json"
if(-not (Test-Path $pkgPath)){ throw ("package.json not found: " + $pkgPath) }
$pkg = Get-Content -Raw -Path $pkgPath | ConvertFrom-Json
if(-not (HasProp $pkg "dependencies"))    { $pkg | Add-Member -NotePropertyName dependencies    -NotePropertyValue ([pscustomobject]@{}) }
if(-not (HasProp $pkg "devDependencies")) { $pkg | Add-Member -NotePropertyName devDependencies -NotePropertyValue ([pscustomobject]@{}) }
Ensure-Prop $pkg "main" "expo-router/entry"
$pkg.dependencies."expo" = "~50.0.17"
$pkg.dependencies."expo-router" = "~3.4.8"
$pkg.dependencies."react" = "18.2.0"
$pkg.dependencies."react-native" = "0.73.6"
$pkg.devDependencies."babel-preset-expo" = "~9.5.2"
Remove-Prop $pkg.devDependencies "@types/react-native"
($pkg | ConvertTo-Json -Depth 100) | Set-Content -Path $pkgPath -Encoding UTF8
Log "package.json normalized"
# ensure babel.config.js
$babelPath = Join-Path $projectRoot "babel.config.js"
if(-not (Test-Path $babelPath)){ $babel = @("module.exports = function(api) {","  api.cache(true);","  return {","    presets: ['babel-preset-expo'],","    plugins: ['expo-router/babel']","  };","};"); Set-Content -Path $babelPath -Value $babel -Encoding UTF8; Log "babel.config.js created" } else { Log "babel.config.js exists" }
# ensure app.json
$appPath = Join-Path $projectRoot "app.json"
if(Test-Path $appPath){ $app = Get-Content -Raw -Path $appPath | ConvertFrom-Json } else { $app = [pscustomobject]@{} }
if(-not (HasProp $app "expo")){ $app | Add-Member -NotePropertyName expo -NotePropertyValue ([pscustomobject]@{}) }
Ensure-Prop $app.expo "name" "FundMind"
Ensure-Prop $app.expo "slug" "fundmind"
Ensure-Prop $app.expo "version" "1.0.0"
Ensure-Prop $app.expo "sdkVersion" "50.0.0"
if(-not (HasProp $app.expo "platforms")){ $app.expo | Add-Member -NotePropertyName platforms -NotePropertyValue @("ios","android","web") }
if(-not (HasProp $app.expo "runtimeVersion")){ $app.expo | Add-Member -NotePropertyName runtimeVersion -NotePropertyValue ([pscustomobject]@{}) }
Ensure-Prop $app.expo.runtimeVersion "policy" "sdkVersion"
($app | ConvertTo-Json -Depth 100) | Set-Content -Path $appPath -Encoding UTF8
Log "app.json normalized"
# clean install
$nm = Join-Path $projectRoot "node_modules"
if(Test-Path $nm){ Log "Remove node_modules"; Remove-Item $nm -Recurse -Force }
$pl = Join-Path $projectRoot "package-lock.json"
if(Test-Path $pl){ Log "Remove package-lock.json"; Remove-Item $pl -Force }
Invoke-CmdLine "npm install"
Log "Starting Expo dev server (tunnel)..."
$extra = ""
if($env:CLEAR -eq "1"){ $extra = " --clear"; Log "Metro cache clear enabled" }
& cmd.exe /c "npx expo start --tunnel$extra"
