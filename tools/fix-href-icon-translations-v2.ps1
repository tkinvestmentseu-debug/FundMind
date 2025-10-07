$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$logsDir = Join-Path $projectRoot "logs"
$logFile = Join-Path $logsDir "fix-href-icon-translations-v2-run-$ts.log"

function Write-Log($msg) { $msg | Tee-Object -FilePath $logFile -Append }

Write-Log "=== Fix Href cleanups, icon bolt, dedup translations ==="

# --- 1. Usuń "as Href" z Redirect/Link ---
$hrefFiles = Get-ChildItem -Path $projectRoot -Recurse -Include *.tsx,*.ts
foreach ($f in $hrefFiles) {
    $content = Get-Content $f.FullName -Raw
    if ($content -match 'href=.*as Href') {
        Write-Log "Czyszczę as Href w: $($f.FullName)"
        $backup = "$($f.FullName).bak.$ts"
        Copy-Item $f.FullName $backup -Force
        $content = $content -replace '\s+as Href', ''
        Set-Content -Path $f.FullName -Value $content -Encoding UTF8
    }
}

# --- 2. Podmień ikonę robot/bot -> bolt ---
$iconFiles = Get-ChildItem -Path $projectRoot -Recurse -Include *.tsx,*.ts
foreach ($f in $iconFiles) {
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

# --- 3. Dedup translations.ts ---
$translationsFile = Join-Path $projectRoot "src\lib\translations.ts"
if (Test-Path $translationsFile) {
    $backup = "$translationsFile.bak.$ts"
    Copy-Item $translationsFile $backup -Force
    Write-Log "Dedup translations.ts"

    $content = Get-Content $translationsFile -Raw
    $regex = '({[\s\S]*})'
    if ($content -match $regex) {
        $jsonLike = $Matches[1] -replace "([a-zA-Z0-9_]+):", '"$1":' # quasi JSON
        try {
            $parsed = $jsonLike | ConvertFrom-Json -ErrorAction Stop
            $deduped = $parsed | ConvertTo-Json -Depth 10
            $newContent = $content -replace $regex, $deduped
            Set-Content -Path $translationsFile -Value $newContent -Encoding UTF8
            Write-Log "translations.ts cleaned"
        } catch {
            Write-Log "Nie udało się sparsować translations.ts, fallback regex"
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
    }
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
    git commit -m "fix: clean href, bolt icon, dedup translations" | Tee-Object -FilePath $logFile -Append
    Write-Log "Commit OK"
} catch {
    Write-Log "Bledy: $_"
} finally {
    Pop-Location
}
