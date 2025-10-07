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
function Ensure-SpecialProp($o,[string]$n,$v){
  if(-not ($o.PSObject.Properties.Name -contains $n)){ $o.PSObject.Properties.Add((New-Object Management.Automation.PSNoteProperty($n,$v))) }
  else { $o.$n = $v }
}
function Invoke-Cmd([string]$cmd){
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
  $out = $proc.StandardOutput.ReadToEnd()
  $err = $proc.StandardError.ReadToEnd()
  $proc.WaitForExit()
  if($out){ Add-Content -Path $log -Value $out -Encoding UTF8 }
  if($err){ Add-Content -Path $log -Value $err -Encoding UTF8 }
  if($proc.ExitCode -eq 0){ Log ("OK: " + $cmd); return $true } else { Log ("FAIL: " + $cmd + " exit " + $proc.ExitCode); return $false }
}
Log "Start v14 (loop fixer + auto Notepad)"
Set-Location $projectRoot
$success = $false
for($i=1; $i -le 3; $i++){
  Log "---- Attempt $i ----"
  try {
    foreach($p in @("node_modules","package-lock.json",".expo",".expo-shared")){ $fp = Join-Path $projectRoot $p; if(Test-Path $fp){ Log ("Remove " + $p); Remove-Item $fp -Recurse -Force -ErrorAction SilentlyContinue } }
    $pkgPath = Join-Path $projectRoot "package.json"
    $pkg = Get-Content -Raw -Path $pkgPath | ConvertFrom-Json
    if(-not (HasProp $pkg "dependencies"))    { $pkg | Add-Member -NotePropertyName dependencies    -NotePropertyValue ([pscustomobject]@{}) }
    if(-not (HasProp $pkg "devDependencies")) { $pkg | Add-Member -NotePropertyName devDependencies -NotePropertyValue ([pscustomobject]@{}) }
    $pkg.dependencies."expo" = "~50.0.17"
    $pkg.dependencies."expo-router" = "~3.4.8"
    $pkg.dependencies."react" = "18.2.0"
    $pkg.dependencies."react-native" = "0.73.6"
    $pkg.devDependencies."babel-preset-expo" = "~9.5.2"
    Ensure-SpecialProp $pkg.devDependencies "@expo/cli" "^0.18.17"
    Remove-Prop $pkg.dependencies "expo-cli"; Remove-Prop $pkg.devDependencies "expo-cli"
    ($pkg | ConvertTo-Json -Depth 100) | Set-Content -Path $pkgPath -Encoding UTF8
    Log "package.json normalized"
    if(-not (Invoke-Cmd "npm install")){ continue }
    $extra = ""
    if($env:CLEAR -eq "1"){ $extra = " --clear"; Log "Metro cache clear enabled" }
    if(Invoke-Cmd ("npx expo start --tunnel" + $extra)){ Log "Expo started OK"; $success = $true; break }
  } catch { Log ("Exception: " + $_.Exception.Message) }
}
Log "Done v14"
Start-Process notepad.exe $log
