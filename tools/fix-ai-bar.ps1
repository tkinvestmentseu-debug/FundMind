$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$logsDir = Join-Path $projectRoot "logs"
$logFile = Join-Path $logsDir "fix-ai-bar-run-$ts.log"

function Write-Log($msg) { $msg | Tee-Object -FilePath $logFile -Append }

Write-Log "=== Fix AI bar margin ==="

# Szukamy pliku z 'Twój Asystent AI'
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

    # Tailwind (mb-x)
    $content = $content -replace "mb-\d+", "mb-2"

    # StyleSheet marginBottom
    $content = $content -replace "marginBottom\s*:\s*\d+", "marginBottom: 8"

    Set-Content -Path $f.FullName -Value $content -Encoding UTF8
}

Push-Location $projectRoot
try {
    Write-Log "Uruchamiam npm run check:all"
    npm run check:all | Tee-Object -FilePath $logFile -Append
    if ($LASTEXITCODE -eq 0) {
        git add .
        git commit -m "fix: AI bar closer to bottom menu" | Tee-Object -FilePath $logFile -Append
        Write-Log "Commit OK"
    } else {
        Write-Log "Bledy w check:all - brak commita"
    }
} finally {
    Pop-Location
}
