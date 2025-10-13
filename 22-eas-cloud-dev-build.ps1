# 22-eas-cloud-dev-build.ps1  (ASCII-only)
$ErrorActionPreference = 'Stop'

# --- Settings ---
$root      = 'D:\FundMind'
$logsDir   = Join-Path $root 'logs'
$appCfg    = Join-Path $root 'app.config.ts'
$easJson   = Join-Path $root 'eas.json'
$slug      = 'fundmind'
$appName   = 'FundMind'
$iosBundle = 'com.fundmind.app'
$andPkg    = 'com.fundmind.app'

function Ensure-Dir([string]$p){ if(!(Test-Path $p)){ New-Item -ItemType Directory -Force -Path $p | Out-Null } }
function Get-Cmd([string]$name){
  $c = Get-Command $name -ErrorAction SilentlyContinue
  if($c){ return $c.Source }
  $c = Get-Command "$name.cmd" -ErrorAction SilentlyContinue
  if($c){ return $c.Source }
  throw "Brak polecenia w PATH: $name(.cmd)"
}
function Run($exe, [string[]]$args, [switch]$Quiet){
  $psi = [System.Diagnostics.ProcessStartInfo]::new()
  $psi.FileName = $exe
  foreach($a in $args){ [void]$psi.ArgumentList.Add($a) }
  $psi.WorkingDirectory = $root
  $psi.UseShellExecute = $false
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError  = $true
  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = $psi
  [void]$p.Start()
  $out = $p.StandardOutput.ReadToEnd()
  $err = $p.StandardError.ReadToEnd()
  $p.WaitForExit()
  if(-not $Quiet -and $out){ Write-Host ($out.Trim()) }
  if($p.ExitCode -ne 0){
    if($err){ Write-Warning ($err.Trim()) }
    throw "Command failed: $exe $($args -join ' ') [code $($p.ExitCode)]"
  }
  return $out
}
function Replace-Or-Insert([string]$text,[string]$pattern,[string]$replacement){
  $opt=[Text.RegularExpressions.RegexOptions]::Singleline
  if([regex]::IsMatch($text,$pattern,$opt)){
    return [regex]::Replace($text,$pattern,$replacement,$opt)
  } else {
    return $text + "`n" + $replacement + "`n"
  }
}

Ensure-Dir $root
Ensure-Dir $logsDir
Set-Location $root
$env:CI = '1'

$npx = Get-Cmd 'npx'
$git = Get-Cmd 'git'

# --- Login (Expo/EAS) ---
$loggedIn = $false
$owner = ''
try {
  $outExpo = (Run $npx @('expo','whoami') -Quiet).Trim()
  if($outExpo -and ($outExpo -notmatch 'not\s+logged\s+in')){ $owner = $outExpo; $loggedIn = $true }
} catch {}
if(-not $loggedIn){
  try {
    $outEas = (Run $npx @('eas','whoami') -Quiet).Trim()
    if($outEas -match 'Logged\s+in\s+as\s+(\S+)'){ $owner = $Matches[1]; $loggedIn = $true }
    elseif($outEas -and ($outEas -notmatch 'not\s+logged')){ $owner = $outEas; $loggedIn = $true }
  } catch {}
}
if(-not $loggedIn -and $env:EXPO_TOKEN){
  try{
    Run $npx @('eas','user:login','--token',$env:EXPO_TOKEN) -Quiet | Out-Null
    $tmp = (Run $npx @('eas','whoami') -Quiet).Trim()
    if($tmp -match 'Logged\s+in\s+as\s+(\S+)'){ $owner=$Matches[1]; $loggedIn=$true }
  } catch {}
}
if(-not $loggedIn -and $env:EXPO_USERNAME -and $env:EXPO_PASSWORD){
  try{
    Run $npx @('expo','login','-u',$env:EXPO_USERNAME,'-p',$env:EXPO_PASSWORD,'--non-interactive')
    $outExpo = (Run $npx @('expo','whoami') -Quiet).Trim()
    if($outExpo -and ($outExpo -notmatch 'not\s+logged\s+in')){ $owner = $outExpo; $loggedIn = $true }
  } catch {}
}
if(-not $loggedIn){ throw "Nie zalogowano do Expo/EAS. Ustaw EXPO_TOKEN lub (EXPO_USERNAME i EXPO_PASSWORD) i uruchom ponownie." }
Write-Host "[OK] Zalogowano jako: $owner"

# --- Git (wymagany przez EAS) ---
$inGit = $false
try { Run $git @('rev-parse','--is-inside-work-tree') -Quiet | Out-Null; $inGit=$true } catch {}
if(-not $inGit){
  Run $git @('init')
  Run $git @('config','user.name', $owner)
  Run $git @('config','user.email', "$owner@users.noreply.expo.dev")
}

# --- app.config.ts scaffold/patch ---
if(!(Test-Path $appCfg)){
@"
export default {
  name: '$appName',
  slug: '$slug',
  owner: '$owner',
  ios: { bundleIdentifier: '$iosBundle' },
  android: { package: '$andPkg' },
  extra: { eas: { projectId: 'PENDING-EAS-PROJECT-ID' } },
} as const;
"@ | Set-Content -Encoding UTF8 $appCfg
} else {
  $cfg = Get-Content -Raw -LiteralPath $appCfg
  $cfg = if($cfg -match "name\s*:\s*['""][^'""]+['""]"){[regex]::Replace($cfg,"name\s*:\s*['""][^'""]+['""]","name: '$appName'")} else { Replace-Or-Insert $cfg 'export\s+default\s*\{' "export default {`n  name: '$appName'," }
  $cfg = if($cfg -match "slug\s*:\s*['""][^'""]+['""]"){[regex]::Replace($cfg,"slug\s*:\s*['""][^'""]+['""]","slug: '$slug'")} else { Replace-Or-Insert $cfg 'export\s+default\s*\{' "export default {`n  slug: '$slug'," }
  $cfg = if($cfg -match "owner\s*:\s*['""][^'""]+['""]"){[regex]::Replace($cfg,"owner\s*:\s*['""][^'""]+['""]","owner: '$owner'")} else { Replace-Or-Insert $cfg 'export\s+default\s*\{' "export default {`n  owner: '$owner'," }
  if($cfg -match 'ios\s*:\s*\{'){
    $cfg = [regex]::Replace($cfg,"bundleIdentifier\s*:\s*['""][^'""]+['""]","bundleIdentifier: '$iosBundle'")
  } else {
    $cfg = [regex]::Replace($cfg,'\}\s*;?\s*$',"  ios: { bundleIdentifier: '$iosBundle' },`n};")
  }
  if($cfg -match 'android\s*:\s*\{'){
    $cfg = [regex]::Replace($cfg,"package\s*:\s*['""][^'""]+['""]","package: '$andPkg'")
  } else {
    $cfg = [regex]::Replace($cfg,'\}\s*;?\s*$',"  android: { package: '$andPkg' },`n};")
  }
  if($cfg -match 'extra\s*:\s*\{[\s\S]*?eas\s*:\s*\{[\s\S]*?projectId'){
    $cfg = [regex]::Replace($cfg,"projectId\s*:\s*['""][^'""]+['""]","projectId: 'PENDING-EAS-PROJECT-ID'",[Text.RegularExpressions.RegexOptions]::Singleline)
  } elseif($cfg -match 'extra\s*:\s*\{'){
    $cfg = [regex]::Replace($cfg,"extra\s*:\s*\{","extra: { eas: { projectId: 'PENDING-EAS-PROJECT-ID' },")
  } else {
    $cfg = [regex]::Replace($cfg,'\}\s*;?\s*$',"  extra: { eas: { projectId: 'PENDING-EAS-PROJECT-ID' } },`n};")
  }
  Set-Content -LiteralPath $appCfg -Value $cfg -Encoding UTF8
}

# --- eas.json patch ---
$easObj = $null
if(Test-Path $easJson){ try{ $easObj = Get-Content -Raw $easJson | ConvertFrom-Json } catch{} }
if(-not $easObj){ $easObj = [ordered]@{} }
if(-not $easObj.build){ $easObj.build = @{} }
if(-not $easObj.build.production){ $easObj.build.production = @{} }
$easObj.build.production.autoIncrement = $true
if(-not $easObj.build.development){
  $easObj.build.development = @{
    developmentClient = $true
    distribution      = "internal"
    android           = @{ buildType = "apk" }
  }
}
if(-not $easObj.cli){ $easObj.cli = @{ version = ">= 13.0.0" } }
($easObj | ConvertTo-Json -Depth 50) | Set-Content -Encoding UTF8 $easJson

# --- commit snapshot ---
Run $git @('add','-A')
try { Run $git @('commit','-m','chore: auto link & build') -Quiet } catch {}

# --- configure (non-interactive) ---
try {
  Run $npx @('eas','build:configure','--platform','android','--non-interactive')
} catch {
  Write-Warning 'eas build:configure pominięte (może już skonfigurowane)'
}

# --- fetch projectId ---
$projectId = ''
try {
  $json = (Run $npx @('eas','project:info','--json') -Quiet)
  $obj  = $null; try{ $obj = $json | ConvertFrom-Json }catch{}
  if($obj -and $obj.projectId){ $projectId = $obj.projectId }
} catch {}
if([string]::IsNullOrWhiteSpace($projectId)){
  $projFile = Join-Path $root '.eas\project.json'
  if(Test-Path $projFile){
    try {
      $pj = Get-Content -Raw $projFile | ConvertFrom-Json
      if($pj -and $pj.projectId){ $projectId = $pj.projectId }
    } catch {}
  }
}
if([string]::IsNullOrWhiteSpace($projectId)){
  throw 'Brak projectId z EAS (konto/organizacja?). Ustaw EXPO_TOKEN albo spróbuj ponownie.'
}

# --- write projectId to app.config.ts ---
$cfg = Get-Content -Raw $appCfg
$cfg = [regex]::Replace($cfg,"projectId\s*:\s*['""][^'""]+['""]","projectId: '$projectId'",[Text.RegularExpressions.RegexOptions]::Singleline)
Set-Content -Encoding UTF8 $appCfg -Value $cfg
Run $git @('add',$appCfg,'.eas','eas.json')
try { Run $git @('commit','-m',"chore: set EAS projectId=$projectId") -Quiet } catch {}

Write-Host "[OK] EAS projectId: $projectId"

# --- cloud build (wait + json) ---
Write-Host "[RUN] EAS build (android/development)"
$buildJson = Run $npx @('eas','build','-p','android','--profile','development','--non-interactive','--wait','--json') -Quiet
$apkUrl = ''
try{
  $build = $buildJson | ConvertFrom-Json
  if($build -and $build.builds -and $build.builds.Count -gt 0){
    $apkUrl = $build.builds[0].artifacts.buildUrl
  }
}catch{}

Write-Host '----------------------------------------'
if($apkUrl){
  Write-Host "APK URL:"
  Write-Host $apkUrl
  Write-Host ""
  Write-Host "Po instalacji Dev Clienta uruchom: npx expo start --dev-client --clear"
}else{
  Write-Host "Build zakonczony. Sprawdz dashboard EAS (link w logach powyzej)."
}
Write-Host '----------------------------------------'