$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$logsDir = Join-Path $projectRoot "logs"
$logFile = Join-Path $logsDir "fix-href-icon-translations-run-$ts.log"

function Write-Log($msg) { $msg | Tee-Object -FilePath $logFile -Append }

Write-Log "=== Fix Href imports, icon, translations, tsconfig ==="

# --- 1. Dodaj import { Href } ---
$hrefFiles = Get-ChildItem -Path $projectRoot -Recurse -Include *.tsx,*.ts | Where-Object {
    Select-String -Path $_.FullName -Pattern 'as Href' -Quiet
}
foreach ($f in $hrefFiles) {
    $content = Get-Content $f.FullName -Raw
    if ($content -notmatch 'import\s+{[^}]*Href[^}]*}\s+from\s+"expo-router"') {
        Write-Log "Dodaję import Href: $($f.FullName)"
        $backup = "$($f.FullName).bak.$ts"
        Copy-Item $f.FullName $backup -Force
        $content = 'import { Href } from "expo-router";' + [Environment]::NewLine + $content
        Set-Content -Path $f.FullName -Value $content -Encoding UTF8
    }
}

# --- 2. Podmień ikonę ---
$iconFiles = Get-ChildItem -Path $projectRoot -Recurse -Include *.tsx,*.ts | Where-Object {
    Select-String -Path $_.FullName -Pattern '"robot"' -Quiet
}
foreach ($f in $iconFiles) {
    $backup = "$($f.FullName).bak.$ts"
    Copy-Item $f.FullName $backup -Force
    Write-Log "Podmieniam ikonę robot->bolt: $($f.FullName)"
    (Get-Content $f.FullName -Raw) -replace '"robot"', '"bolt"' |
        Set-Content -Path $f.FullName -Encoding UTF8
}

# --- 3. Napraw translations.ts ---
$translationsFile = Join-Path $projectRoot "src\lib\translations.ts"
if (Test-Path $translationsFile) {
    $backup = "$translationsFile.bak.$ts"
    Copy-Item $translationsFile $backup -Force
    Write-Log "Czyszczę duplikaty w translations.ts"

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

# --- 4. Update tsconfig.json exclude ---
$tsconfig = Join-Path $projectRoot "tsconfig.json"
if (Test-Path $tsconfig) {
    $json = Get-Content $tsconfig -Raw | ConvertFrom-Json
    if (-not $json.exclude) { $json | Add-Member -MemberType NoteProperty -Name exclude -Value @() }
    if ($json.exclude -notcontains "backups") {
        $json.exclude += "backups"
        Write-Log "Dodano 'backups' do exclude w tsconfig.json"
    }
    $json | ConvertTo-Json -Depth 10 | Set-Content -Path $tsconfig -Encoding UTF8
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
    git commit -m "fix: add Href import, bolt icon, dedup translations, exclude backups" | Tee-Object -FilePath $logFile -Append
    Write-Log "Commit OK"
} catch {
    Write-Log "Bledy: $_"
} finally {
    Pop-Location
}
