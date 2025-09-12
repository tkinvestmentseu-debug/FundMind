Write-Host "[Guardian] Running checks..."
npm run lint
if ($LASTEXITCODE -ne 0) { exit 1 }
npm run typecheck
if ($LASTEXITCODE -ne 0) { exit 1 }
npm run test
if ($LASTEXITCODE -ne 0) { exit 1 }
Write-Host "[Guardian] All checks passed."
