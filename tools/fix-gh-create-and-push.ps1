$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logsDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir | Out-Null }
$logPath = Join-Path $logsDir ("fix-gh-create-and-push-run-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

$repo = "FundMind"
$owner = gh api user --jq .login
$fullRepo = "$owner/$repo"

Set-Location $projectRoot

Write-Output "[fix-gh] Ensuring repo $fullRepo exists..."
$exists = $true
try {
    gh repo view $fullRepo | Out-Null
} catch {
    $exists = $false
}

if (-not $exists) {
    Write-Output "[fix-gh] Repo not found. Creating..."
    gh repo create $fullRepo --public --source . --remote origin --push | Tee-Object -FilePath $logPath -Append
} else {
    Write-Output "[fix-gh] Repo already exists. Resetting origin..."
    git remote remove origin 2>$null
    git remote add origin "https://github.com/$fullRepo.git"
}

$current = git rev-parse --abbrev-ref HEAD
if ($current -eq "master") {
    Write-Output "[fix-gh] Renaming 'master' to 'main'..."
    git branch -m master main | Tee-Object -FilePath $logPath -Append
}

$changes = git status --porcelain
if ($changes) {
    git add . | Tee-Object -FilePath $logPath -Append
    git commit -m "Automated push to GitHub" | Tee-Object -FilePath $logPath -Append
}

git push -u origin main | Tee-Object -FilePath $logPath -Append
Write-Output "[fix-gh] Done. Full log: $logPath"
