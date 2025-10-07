param(
  [string]$projectRoot = "D:\FundMind",
  [string]$devIP = "192.168.0.16",
  [int]$devPort = 8081,
  [switch]$clearMetro = $false
)
$ErrorActionPreference = "Stop"
Set-Location -LiteralPath $projectRoot
$env:REACT_NATIVE_PACKAGER_HOSTNAME = $devIP
$extra = ""
if ($clearMetro) { $extra = "--clear" }
Write-Host "Starting Expo dev server on $devIP:$devPort ..."
# Pin port via env var EXPO_DEV_SERVER_PORT (applies to SDK 50)
$env:EXPO_DEV_SERVER_PORT = "$devPort"
# Run
npx expo start $extra
