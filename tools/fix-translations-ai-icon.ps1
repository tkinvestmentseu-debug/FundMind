$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$logsDir = Join-Path $projectRoot "logs"
$logFile = Join-Path $logsDir "fix-translations-ai-icon-run-$ts.log"

function Write-Log($msg) { $msg | Tee-Object -FilePath $logFile -Append }

Write-Log "=== Fix translations, routes and icon ==="

# --- 1. Fix translations.ts duplicates ---
$translationsFile = Join-Path $projectRoot "src\lib\translations.ts"
if (Test-Path $translationsFile) {
    $backup = "$translationsFile.bak.$ts"
    Copy-Item $translationsFile $backup -Force
    Write-Log "Backup translations: $backup"

    $lines = Get-Content $translationsFile
    $seen = @{}
    $fixed = @()

    foreach ($line in $lines) {
        if ($line -match "^\s*['""]([^'""]+)['""]\s*:") {
            $key = $Matches[1]
            if ($seen.ContainsKey($key)) {
                Write-Log "Usuwam duplikat klucza: $key"
                continue
            } else {
                $seen[$key] = $true
            }
        }
        $fixed += $line
    }

    Set-Content -Path $translationsFile -Value $fixed -Encoding UTF8
}

# --- 2. Fix hardcoded routes ---
$targets = Get-ChildItem -Path $projectRoot -Recurse -Include *.tsx,*.ts | Where-Object {
    Select-String -Path $_.FullName -Pattern '"/ai"|"/\(tabs\)"' -Quiet
}

foreach ($f in $targets) {
    $backup = "$($f.FullName).bak.$ts"
    Copy-Item $f.FullName $backup -Force
    Write-Log "Backup route file: $($f.FullName)"

    $content = Get-Content $f.FullName -Raw
    $content = $content -replace '"/ai"', '"/ai" as Href'
    $content = $content -replace '"/\(tabs\)"', '"/(tabs)" as Href'
    Set-Content -Path $f.FullName -Value $content -Encoding UTF8
}

# --- 3. Fix icon 'robot' -> 'bot' ---
$icons = Get-ChildItem -Path $projectRoot -Recurse -Include *.tsx,*.ts | Where-Object {
    Select-String -Path $_.FullName -Pattern '"robot"' -Quiet
}
foreach ($f in $icons) {
    $backup = "$($f.FullName).bak.$ts"
    Copy-Item $f.FullName $backup -Force
    Write-Log "Backup icon file: $($f.FullName)"

    (Get-Content $f.FullName -Raw) -replace '"robot"', '"bot"' |
        Set-Content -Path $f.FullName -Encoding UTF8
}

# --- Run checks ---
Push-Location $projectRoot
try {
    Write-Log "Lint..."
    npm run lint --max-warnings=0 | Tee-Object -FilePath $logFile -Append
    if ($LASTEXITCODE -ne 0) { throw "Lint errors" }

    Write-Log "Typecheck..."
    npm run typecheck | Tee-Object -FilePath $logFile -Append
    if ($LASTEXITCODE -ne 0) { throw "Typecheck errors" }

    Write-Log "Tests..."
    npm run test:run | Tee-Object -FilePath $logFile -Append
    if ($LASTEXITCODE -ne 0) { throw "Test errors" }

    git add .
    git commit -m "fix: dedup translations, fix routes /ai, replace robot icon" | Tee-Object -FilePath $logFile -Append
    Write-Log "Commit OK"
} catch {
    Write-Log "Bledy: $_"
} finally {
    Pop-Location
}
