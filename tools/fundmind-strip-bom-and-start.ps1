# fundmind-strip-bom-and-start.ps1 — usuń BOM z JSON i uruchom Metro w Expo Go
$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir     = "$projectRoot\logs"
$logFile     = "$logsDir\strip-bom.log"

function Log($m){ $t=Get-Date -Format s; Write-Host "[StripBOM] $m"; "$t $m" | Out-File $logFile -Encoding UTF8 -Append }

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
  Log "Start stripping BOM from key files"

  @("package.json","app.json","babel.config.js","metro.config.js") | ForEach-Object {
    $f = Join-Path $projectRoot $_
    Remove-BOM $f
  }

  Log "All BOM stripped. Starting Metro in Expo Go mode..."
  npx expo start --go --lan
}
catch {
  Log "ERROR: $_"
  exit 1
}
