$ErrorActionPreference = 'Stop'
$env:REACT_NATIVE_PACKAGER_HOSTNAME = (Get-Content ".packager-ip" -ErrorAction SilentlyContinue)
if ([string]::IsNullOrWhiteSpace($env:REACT_NATIVE_PACKAGER_HOSTNAME)) { $env:REACT_NATIVE_PACKAGER_HOSTNAME = "192.168.0.16" }
Set-Location $PSScriptRoot
npx expo start --clear --port 8081 --host lan
