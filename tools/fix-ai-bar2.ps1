$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$logsDir = Join-Path $projectRoot "logs"
$logFile = Join-Path $logsDir "fix-ai-bar2-run-$ts.log"

function Write-Log($msg) { $msg | Tee-Object -FilePath $logFile -Append }

Write-Log "=== Fix AI bar margin (v2) ==="

$files = Get-ChildItem -Path $projectRoot -Recurse -Include *.tsx,*.ts | Where-Object {
    Select-String -Path $_.FullName -Pattern "Twój Asystent AI" -Quiet
}

if (-not $files) {
    Write-Log "Nie znaleziono pliku z przyciskiem AI"
    exit 1
}

foreach ($f in $files) {
    Write-Log "Poprawiam: $($f.FullName)"
    $backup = "$($f.FullName).bak.$ts"
    Copy-Item $f.FullName $backup -Force

    $content = Get-Content $f.FullName -Raw
    $content = $content -replace "mb-\d+", "mb-2"
    $content = $content -replace "marginBottom\s*:\s*\d+", "marginBottom: 8"
    Set-Content -Path $f.FullName -Value $content -Encoding UTF8
}

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

    git add .
    git commit -m "fix: AI bar closer to bottom menu" | Tee-Object -FilePath $logFile -Append
    Write-Log "Commit OK"
} catch {
    Write-Log "Bledy: $_"
} finally {
    Pop-Location
}
