$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$logsDir = Join-Path $projectRoot "logs"
$logFile = Join-Path $logsDir "fix-tsconfig-bundler-run-$ts.log"

function Write-Log($msg) { $msg | Tee-Object -FilePath $logFile -Append }

Write-Log "=== Fix tsconfig: enforce moduleResolution=bundler ==="

$tsconfig = Join-Path $projectRoot "tsconfig.json"
if (-not (Test-Path $tsconfig)) {
    Write-Log "Brak tsconfig.json"
    exit 1
}

$backup = "$tsconfig.bak.$ts"
Copy-Item $tsconfig $backup -Force
Write-Log "Backup zapisany: $backup"

# wczytaj jako obiekt JSON
$json = Get-Content $tsconfig -Raw | ConvertFrom-Json

if (-not $json.compilerOptions) {
    $json | Add-Member -MemberType NoteProperty -Name compilerOptions -Value (@{})
}

if ($json.compilerOptions.moduleResolution -ne "bundler") {
    $json.compilerOptions.moduleResolution = "bundler"
    Write-Log "Ustawiono moduleResolution=bundler"
}

# zapisz z powrotem (ładny JSON, UTF8)
$json | ConvertTo-Json -Depth 10 | Set-Content -Path $tsconfig -Encoding UTF8

Push-Location $projectRoot
try {
    Write-Log "Sprawdzam lint..."
    npm run lint --max-warnings=0 | Tee-Object -FilePath $logFile -Append
    if ($LASTEXITCODE -ne 0) { throw "Lint errors" }

    Write-Log "Sprawdzam typecheck..."
    npm run typecheck | Tee-Object -FilePath $logFile -Append
    if ($LASTEXITCODE -ne 0) { throw "Typecheck errors" }

    Write-Log "Sprawdzam testy..."
    npm run test:run | Tee-Object -FilePath $logFile -Append
    if ($LASTEXITCODE -ne 0) { throw "Test errors" }

    git add tsconfig.json
    git commit -m "fix: tsconfig use bundler moduleResolution for customConditions" | Tee-Object -FilePath $logFile -Append
    Write-Log "Commit OK"
} catch {
    Write-Log "Bledy: $_"
} finally {
    Pop-Location
}
