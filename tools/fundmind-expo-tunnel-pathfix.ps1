# fundmind-expo-tunnel-pathfix.ps1
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir     = "$projectRoot\logs"
$logFile     = "$logsDir\expo-tunnel-pathfix.log"

function Log($m){ $t=Get-Date -Format s; Write-Host "[TunnelPATH] $m"; "$t $m" | Out-File $logFile -Encoding UTF8 -Append }

try {
  Set-Location $projectRoot

  # 1) Ustaw COMSPEC
  $cmdPath = "$env:SystemRoot\System32\cmd.exe"
  if (!(Test-Path $cmdPath)) { throw "cmd.exe not found at $cmdPath" }
  $env:COMSPEC = $cmdPath
  Log "Set COMSPEC = $cmdPath"

  # 2) Napraw PATH – dołóż git i node global
  $gitPath = "C:\Program Files\Git\bin"
  $nodePath = (Get-Command node.exe).Source | Split-Path
  $npmPath = (Get-Command npm.cmd).Source | Split-Path
  $env:PATH = "$gitPath;$nodePath;$npmPath;$env:PATH"
  Log "Ensured PATH includes git/node/npm"

  # 3) Wyczyść cache Metro
  if (Test-Path "$projectRoot\.expo"){ Remove-Item -Recurse -Force "$projectRoot\.expo" }
  if (Test-Path "$projectRoot\.expo-shared"){ Remove-Item -Recurse -Force "$projectRoot\.expo-shared" }

  # 4) Odpal Metro przez cmd.exe, ale fallback na PowerShell jeśli ENOENT
  Log "Starting Metro with tunnel..."
  & $cmdPath "/c" "npx.cmd expo start --tunnel"
  if ($LASTEXITCODE -ne 0) {
    Log "Fallback: try PowerShell spawn"
    npx expo start --tunnel
  }
}
catch {
  Log "ERROR: $_"
  exit 1
}
