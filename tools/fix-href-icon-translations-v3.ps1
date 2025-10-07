$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$logsDir = Join-Path $projectRoot "logs"
$logFile = Join-Path $logsDir "fix-href-icon-translations-v3-run-$ts.log"

function Write-Log($msg) { $msg | Tee-Object -FilePath $logFile -Append }

Write-Log "=== Fix Href cleanups, icon bolt, dedup translations (safe paths) ==="

# --- 1. Ogranicz scope tylko do app/, components/, src/ ---
$scanDirs = @("app","components","src")
$tsFiles = foreach ($d in $scanDirs) {
    Get-ChildItem -Path (Join-Path $projectRoot $d) -Recurse -Include *.tsx,*.ts -File -ErrorAction SilentlyContinue
}

# --- 2. Usuń "as Href" ---
foreach ($f in $tsFiles) {
    $content = Get-Content $f.FullName -Raw
    if ($content -match 'href=.*as Href') {
        Write-Log "Czyszczę as Href w: $($f.FullName)"
        $backup = "$($f.FullName).bak.$ts"
        Copy-Item $f.FullName $backup -Force
        $content = $content -replace '\s+as Href', ''
        Set-Content -Path $f.FullName -Value $content -Encoding UTF8
    }
}

# --- 3. Ikony robot/bot -> bolt ---
foreach ($f in $tsFiles) {
    $content = Get-Content $f.FullName -Raw
    if ($content -match '"robot"' -or $content -match '"bot"') {
        Write-Log "Podmieniam ikonę na bolt: $($f.FullName)"
        $backup = "$($f.FullName).bak.$ts"
        Copy-Item $f.FullName $backup -Force
        $content = $content -replace '"robot"', '"bolt"'
        $content = $content -replace '"bot"', '"bolt"'
        Set-Content -Path $f.FullName -Value $content -Encoding UTF8
    }
}

# --- 4. Dedup translations.ts ---
$translationsFile = Join-Path $projectRoot "src\lib\translations.ts"
if (Test-Path $translationsFile) {
    $backup = "$translationsFile.bak.$ts"
    Copy-Item $translationsFile $backup -Force
    Write-Log "Dedup translations.ts"

    $lines = Get-Content $translationsFile
    $seen = @{}
    $fixed = @()

    foreach ($line in $lines) {
        if ($line -match "^\s*['""]([^'""]+)['""]\s*:") {
            $key = $Matches[1]
            if ($seen.ContainsKey($key)) { continue }
            $seen[$key] = $true
        }
        $fixed += $line
    }

    Set-Content -Path $translationsFile -Value $fixed -Encoding UTF8
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
    git commit -m "fix: clean href, bolt icon, dedup translations (v3 safe)" | Tee-Object -FilePath $logFile -Append
    Write-Log "Commit OK"
} catch {
    Write-Log "Bledy: $_"
} finally {
    Pop-Location
}
