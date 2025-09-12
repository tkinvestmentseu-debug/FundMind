# fundmind-start-expo-go-global.ps1  start przez globalny expo-cli (SDK 49, Expo Go, LAN)
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir     = "$projectRoot\logs"
$logFile     = "$logsDir\start-expo-go-global.log"

function Log($m){ $t=Get-Date -Format s; Write-Host "[StartGlobal] $m"; "$t $m" | Out-File $logFile -Encoding UTF8 -Append }

function Remove-BOM($path){
  if (Test-Path $path){
    $raw = Get-Content $path -Raw -Encoding Byte
    if ($raw.Length -ge 3 -and $raw[0] -eq 239 -and $raw[1] -eq 187 -and $raw[2] -eq 191){
      $clean = $raw[3..($raw.Length-1)]
      [IO.File]::WriteAllBytes($path,$clean)
      Log "Removed BOM from $(Split-Path $path -Leaf)"
    }
  }
}

try {
  Set-Location $projectRoot
  Log "Starting FundMind via global expo-cli"

  # 0) Ustaw stabilne środowisko
  $env:COMSPEC = "$env:SystemRoot\System32\cmd.exe"
  $env:BROWSER = "none"             # nie otwieraj przeglądarki
  $env:EXPO_NO_DOCTOR = "1"         # nie odpalaj doktora (mniej spawnów)
  if (!(Test-Path $env:COMSPEC)) { throw "cmd.exe not found at $($env:COMSPEC)" }
  Log "COMSPEC set to $($env:COMSPEC)"

  # 1) Usuń BOM z newralgicznych plików
  @("package.json","app.json") | ForEach-Object { Remove-BOM (Join-Path $projectRoot $_) }

  # 2) Wyczyść cache Expo
  if (Test-Path "$projectRoot\.expo")        { Remove-Item -Recurse -Force "$projectRoot\.expo" }
  if (Test-Path "$projectRoot\.expo-shared") { Remove-Item -Recurse -Force "$projectRoot\.expo-shared" }
  Log "Cleared .expo caches"

  # 3) Zainstaluj/Sprawdź globalny expo-cli (6.3.9 stabilne dla SDK49)
  $needInstall = $true
  try {
    $expoCmd = Get-Command expo.cmd -ErrorAction Stop
    $ver = (& $expoCmd.Source --version) 2>$null
    if ($ver -and ($ver -like "6.*")) { $needInstall = $false }
  } catch { $needInstall = $true }

  if ($needInstall) {
    Log "Installing global expo-cli@6.3.9 ..."
    npm install -g expo-cli@6.3.9 | Out-Null
    $expoCmd = Get-Command expo.cmd -ErrorAction Stop
    Log "Installed global expo-cli: $((& $expoCmd.Source --version) 2>$null)"
  } else {
    Log "Using global expo-cli: $ver"
  }

  # 4) Start przez globalny expo-cli (omijamy lokalny @expo/cli i cross-spawn)
  Log "Starting Expo (Expo Go mode, LAN, no devtools)"
  & $expoCmd.Source start --go --lan --no-devtools
}
catch {
  Log "ERROR: $_"
  exit 1
}
