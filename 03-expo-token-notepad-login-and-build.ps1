# 03-expo-token-notepad-login-and-build.ps1 (v3 hardened)
$ErrorActionPreference='Stop'
$root='D:\FundMind'
$secrets=Join-Path $root 'secrets'
$tokenFile=Join-Path $secrets 'expo_token.txt'
$buildScript=Join-Path $root '22-eas-cloud-dev-build.ps1'
$logsDir=Join-Path $root 'logs'
$ts=Get-Date -Format 'yyyyMMdd-HHmmss'
$log=Join-Path $logsDir "eas-auth-$ts.txt"
$env:CI='1'; $env:NO_COLOR='1'

function Ensure-Dir { param([string]$p)
  if([string]::IsNullOrWhiteSpace($p)){ return }
  if(!(Test-Path -LiteralPath $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null }
}
function Log([string]$m){ Ensure-Dir $logsDir; $m | Add-Content -Encoding UTF8 $log }
function Resolve-Tool{ param([string]$n)
  foreach($cand in @("$n.cmd","$n.exe","$n.bat",$n)){
    $g=Get-Command $cand -ErrorAction SilentlyContinue
    if($g){ return $g.Source }
  }
  throw "Tool not in PATH: $n"
}
function Run-Tool{ param([string]$tool,[string[]]$args,[switch]$Quiet,[string]$wd=$root)
  $psi=New-Object System.Diagnostics.ProcessStartInfo
  $psi.WorkingDirectory=$wd; $psi.UseShellExecute=$false
  $psi.RedirectStandardOutput=$true; $psi.RedirectStandardError=$true
  if($tool -match '\.ps1$'){
    $pwsh=(Get-Command 'pwsh' -ErrorAction SilentlyContinue).Source
    if(-not $pwsh){ $pwsh=(Get-Command 'powershell' -ErrorAction Stop).Source }
    $psi.FileName=$pwsh; $psi.Arguments="-NoProfile -ExecutionPolicy Bypass -File `"$tool`" " + ($args -join ' ')
  } else {
    $psi.FileName=$tool; $psi.Arguments=($args -join ' ')
  }
  Log ">> $($psi.FileName) $($psi.Arguments)"
  $p=[System.Diagnostics.Process]::Start($psi)
  $out=$p.StandardOutput.ReadToEnd(); $err=$p.StandardError.ReadToEnd()
  $p.WaitForExit()
  if($out){ Log $out.Trim() }; if($err){ Log ("ERR: " + $err.Trim()) }
  if($p.ExitCode -ne 0){ throw ("{0} failed (code {1}): {2} {3}" -f $tool,$p.ExitCode,$err,$out) }
  if(-not $Quiet -and $out){ Write-Host ($out.Trim()) }
  return $out
}
function Eas { param([string[]]$ea) $npx=Resolve-Tool 'npx'; Run-Tool $npx (@('--yes','eas-cli@latest') + $ea) -Quiet }

# przygotowanie
Ensure-Dir $root; Ensure-Dir $secrets; Ensure-Dir $logsDir
if(!(Test-Path $buildScript)){ throw "Missing file: $buildScript" }

# utwórz/odśwież szablon tokenu BEZ ryzyka Get-Item na nieistniejącym pliku
if(!(Test-Path $tokenFile)){
  $tpl = "# EXPO/EAS ACCESS TOKEN`r`n# Paste your token on ONE line below, then Save (Ctrl+S) and close Notepad.`r`n# Example: EAS-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`r`n"
  [IO.File]::WriteAllText($tokenFile,$tpl,[Text.UTF8Encoding]::new($false))
} elseif(([string](Get-Content -Raw $tokenFile)).Length -eq 0){
  $tpl = "# EXPO/EAS ACCESS TOKEN`r`n# Paste your token on ONE line below, then Save (Ctrl+S) and close Notepad.`r`n# Example: EAS-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX`r`n"
  [IO.File]::WriteAllText($tokenFile,$tpl,[Text.UTF8Encoding]::new($false))
}

# Notatnik
$np = Start-Process -FilePath "notepad.exe" -ArgumentList "`"$tokenFile`"" -PassThru
$np.WaitForExit()

# token: pierwsza niepusta linia bez komentarza
$raw=(Get-Content -Raw $tokenFile); $token=''
foreach($line in ($raw -split "`r?`n")){
  $l=$line.Trim()
  if($l -and -not $l.StartsWith('#') -and -not $l.StartsWith(';')){
    if( ($l.StartsWith('"') -and $l.EndsWith('"')) -or ($l.StartsWith("'") -and $l.EndsWith("'")) ){ $l=$l.Substring(1,$l.Length-2) }
    $token=$l.Trim(); break
  }
}
if([string]::IsNullOrWhiteSpace($token)){ throw "Token not found in $tokenFile. Paste a valid EAS token (single line) and rerun." }
if($token -match '\s'){ throw "Token contains whitespace/newlines. Paste it on a single line." }
try{ if(Test-Path $tokenFile){ (Get-Item $tokenFile).Attributes='Hidden' } }catch{}
$env:EXPO_TOKEN=$token; Log "Using EXPO_TOKEN (len=$($token.Length))."

# login
try{ Eas @('logout') | Out-Null }catch{ Log "logout failed/ignored" }
Eas @('user:login','--token',$token) | Out-Null

# whoami → JSON preferowane
$json=''; $username=''
try{ $json=Eas @('whoami','--json') }catch{ Log "whoami --json failed; trying plain" }
if($json){
  try{
    $obj=$json | ConvertFrom-Json
    if($obj.username){ $username=$obj.username }
    elseif($obj.user -and $obj.user.username){ $username=$obj.user.username }
    elseif($obj.account -and $obj.account.name){ $username=$obj.account.name }
  }catch{ Log "JSON parse fail: $($_.Exception.Message)" }
}
if([string]::IsNullOrWhiteSpace($username)){
  try{
    $plain=(Eas @('whoami'))
    if($plain -match 'Logged\s+in\s+as\s+(\S+)'){ $username=$Matches[1] }
    elseif($plain){ $username=($plain -split '\s+')[0] }
  }catch{}
}
if([string]::IsNullOrWhiteSpace($username)){ Log "EAS login failed with provided token."; throw "EAS login failed. Check $log and verify the token in $tokenFile." }

Write-Host "[OK] Logged in as: $username"; Log "[OK] Logged in as: $username"

# build
Run-Tool $buildScript @()
Write-Host "Log zapisany: $log"