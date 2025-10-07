$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$tsconfig = Join-Path $projectRoot "tsconfig.json"
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path (Join-Path $projectRoot "logs") "fix-jest-types-run-$ts.log"

function Write-Log($msg) { $msg | Tee-Object -FilePath $logFile -Append }

Write-Log "=== Install @types/jest and update tsconfig ==="

Push-Location $projectRoot
npm install --save-dev @types/jest | Tee-Object -FilePath $logFile -Append
Pop-Location

$json = Get-Content $tsconfig -Raw | ConvertFrom-Json

if (-not $json.compilerOptions) {
    $json | Add-Member -MemberType NoteProperty -Name compilerOptions -Value (@{})
}

if (-not $json.compilerOptions.types) {
    $json.compilerOptions | Add-Member -MemberType NoteProperty -Name types -Value @()
}

if ($json.compilerOptions.types -notcontains "jest") {
    $json.compilerOptions.types += "jest"
    Write-Log "Dodano 'jest' do compilerOptions.types"
}

$json | ConvertTo-Json -Depth 10 | Set-Content -Path $tsconfig -Encoding UTF8
Write-Log "Zapisano tsconfig.json"
