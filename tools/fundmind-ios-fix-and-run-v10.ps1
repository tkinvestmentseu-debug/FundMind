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
function Invoke-Cmd([string]$cmd){ Log ("Run: " + $cmd); & cmd.exe /d /s /c $cmd *>&1 | Add-Content -Path $log -Encoding UTF8; if($LASTEXITCODE -eq 0){ Log ("OK: " + $cmd) } else { throw ("FAIL (" + $cmd + ") exit " + $LASTEXITCODE) } }
Log "Start v10"
Set-Location $projectRoot
Log "Uninstall legacy expo-cli (global and local)"
try { Invoke-Cmd "npm uninstall -g expo-cli" } catch { Log "global expo-cli not found" }
try { Invoke-Cmd "npm uninstall expo-cli" } catch { Log "local expo-cli not found" }
# normalize package.json
$pkgPath = Join-Path $projectRoot "package.json"
if(-not (Test-Path $pkgPath)){ throw ("package.json not found: " + $pkgPath) }
$pkg = Get-Content -Raw -Path $pkgPath | ConvertFrom-Json
if(-not (HasProp $pkg "dependencies"))    { $pkg | Add-Member -NotePropertyName dependencies    -NotePropertyValue ([pscustomobject]@{}) }
if(-not (HasProp $pkg "devDependencies")) { $pkg | Add-Member -NotePropertyName devDependencies -NotePropertyValue ([pscustomobject]@{}) }
$pkg.dependencies."expo" = "~50.0.17"
$pkg.dependencies."expo-router" = "~3.4.8"
$pkg.dependencies."react" = "18.2.0"
$pkg.dependencies."react-native" = "0.73.6"
$pkg.devDependencies."babel-preset-expo" = "~9.5.2"
Remove-Prop $pkg.devDependencies "expo-cli"
Remove-Prop $pkg.dependencies "expo-cli"
($pkg | ConvertTo-Json -Depth 100) | Set-Content -Path $pkgPath -Encoding UTF8
Log "package.json normalized"
# ensure app.json minimal
$appPath = Join-Path $projectRoot "app.json"
if(Test-Path $appPath){ $app = Get-Content -Raw -Path $appPath | ConvertFrom-Json } else { $app = [pscustomobject]@{} }
if(-not (HasProp $app "expo")){ $app | Add-Member -NotePropertyName expo -NotePropertyValue ([pscustomobject]@{}) }
Ensure-Prop $app.expo "name" "FundMind"
Ensure-Prop $app.expo "slug" "fundmind"
Ensure-Prop $app.expo "version" "1.0.0"
Ensure-Prop $app.expo "sdkVersion" "50.0.0"
Ensure-Prop $app.expo "runtimeVersion" ([pscustomobject]@{ policy = "sdkVersion" })
($app | ConvertTo-Json -Depth 100) | Set-Content -Path $appPath -Encoding UTF8
Log "app.json normalized"
# clean install
$nm = Join-Path $projectRoot "node_modules"
if(Test-Path $nm){ Log "Remove node_modules"; Remove-Item $nm -Recurse -Force }
$pl = Join-Path $projectRoot "package-lock.json"
if(Test-Path $pl){ Log "Remove package-lock.json"; Remove-Item $pl -Force }
Invoke-Cmd "npm install"
Log "Starting Expo (tunnel)..."
$extra = ""
if($env:CLEAR -eq "1"){ $extra = " --clear"; Log "Metro cache clear enabled" }
Invoke-Cmd "npx expo start --tunnel$extra"
