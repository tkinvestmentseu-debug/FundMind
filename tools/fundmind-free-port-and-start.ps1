param(
  [string]$HostIP = "192.168.0.16",
  [int[]]$Ports = @(8081,19000,19001)
)

$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }
$logFile = Join-Path $logDir ("free-port-and-start-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

function Log($m){ Add-Content -Path $logFile -Value ("["+(Get-Date -Format "HH:mm:ss")+"] "+$m) }

function Kill-Port([int]$port){
  try {
    $conns = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if ($conns) {
      $pids = $conns | Select-Object -ExpandProperty OwningProcess -Unique
      foreach($pid in $pids){
        try {
          $proc = Get-Process -Id $pid -ErrorAction SilentlyContinue
          if ($proc) { Log "Killing PID ${pid} ($($proc.ProcessName)) on :${port}"; Stop-Process -Id $pid -Force }
        } catch { Log "Stop-Process failed for PID ${pid}: $($_.Exception.Message)" }
      }
    } else {
      Log "Port :${port} free."
    }
  } catch {
    Log "Get-NetTCPConnection failed for :${port}: $($_.Exception.Message)"
  }
}

function Wait-Port-Free([int]$port, [int]$timeoutSec = 10){
  $deadline = (Get-Date).AddSeconds($timeoutSec)
  while((Get-Date) -lt $deadline){
    $c = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    if (-not $c) { Log "Port :${port} is free."; return $true }
    Start-Sleep -Milliseconds 300
  }
  Log "Timeout waiting for :${port} to free."
  return $false
}

Set-Location $projectRoot
foreach($p in $Ports){ Kill-Port $p; Wait-Port-Free $p | Out-Null }

# optional: remove Metro cache
$metroCache = Join-Path $projectRoot "node_modules\.cache\metro"
if (Test-Path $metroCache) { try { Remove-Item $metroCache -Recurse -Force -ErrorAction SilentlyContinue; Log "Removed metro cache." } catch {} }

# env for child process
$env:RCT_METRO_PORT = "8081"
$env:REACT_NATIVE_PACKAGER_HOSTNAME = $HostIP

Log "Starting Expo on $HostIP:8081 with --clear"
Start-Process -FilePath "npx" -ArgumentList "expo start --clear --lan" -NoNewWindow
