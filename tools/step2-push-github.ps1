$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
Set-Location $projectRoot

# init repo if missing
if (-not (Test-Path (Join-Path $projectRoot ".git"))) {
  git init | Out-Null
  Write-Output "[step2] git repo initialized."
}

# .gitignore
$gitignore = @"
node_modules/
npm-debug.log
dist/
.expo/
.expo-shared/
*.log
*.tmp
*.bak
*.swp
*.DS_Store
*.orig
.idea/
.vscode/
coverage/
android/
ios/
"@
Set-Content -Path (Join-Path $projectRoot ".gitignore") -Value $gitignore -Encoding UTF8

# .gitattributes
$gitattributes = @"
* text=auto eol=lf
*.ps1 text eol=crlf
"@
Set-Content -Path (Join-Path $projectRoot ".gitattributes") -Value $gitattributes -Encoding UTF8

# stage + commit
git add . | Out-Null
git commit -m "init: FundMind Expo app" | Out-Null

# GitHub login (token needed)
Write-Output "[step2] Logging into GitHub CLI (paste your PAT)..."
gh auth login --with-token

# repo create (private)
$repoName = "FundMind"
gh repo create $repoName --private --source=. --remote=origin --push

Write-Output "[step2] Repo created & pushed: $repoName"
