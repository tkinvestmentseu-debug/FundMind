$ErrorActionPreference = 'Stop'
$from = $PSScriptRoot
$to   = 'D:\FundMind'
robocopy "$from" "$to" /MIR /XJ /R:1 /W:1 /MT:16
Write-Host "Przywrócono projekt do $to"
