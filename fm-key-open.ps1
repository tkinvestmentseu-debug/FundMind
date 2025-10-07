param(
  [string]$RepoPath   = "D:\FundMind",
  [string]$KeyFileRel = ".secrets\openai.key"
)

$ErrorActionPreference = 'Stop'
Set-Location $RepoPath

# Ścieżki
$fullKeyPath = Join-Path (Get-Location) $KeyFileRel
$secretsDir  = Split-Path $fullKeyPath -Parent
if (-not (Test-Path $secretsDir)) { New-Item -ItemType Directory -Force -Path $secretsDir | Out-Null }

# Szablon pliku z instrukcją (jeśli pusty/nie istnieje)
$needsTemplate = -not (Test-Path $fullKeyPath) -or -not ((Get-Content $fullKeyPath -ErrorAction SilentlyContinue) -ne $null)
if ($needsTemplate) {
@"
# Wklej TYLKO swój OpenAI API key poniżej (jedna linia).
# Przykład: sk-... lub sk-proj-...
# Zapisz i zamknij Notatnik, a potem uruchom: .\fm-key-apply.ps1
"@ | Set-Content -Path $fullKeyPath -Encoding UTF8
}

# Dopisz reguły do .gitignore (literalnie)
if (-not (Test-Path ".gitignore")) { New-Item ".gitignore" -ItemType File | Out-Null }
$giLines = Get-Content ".gitignore" -ErrorAction SilentlyContinue
$toAdd = @()
$ruleSecretsDir = ((Split-Path $KeyFileRel -Parent) + "/")
foreach ($rule in @($ruleSecretsDir, "**/openai-key.txt", ".env", ".env.*", ".archive/")) {
  if ($rule -and ($giLines -notcontains $rule)) { $toAdd += $rule }
}
if ($toAdd.Count) { Add-Content ".gitignore" ("`n" + ($toAdd -join "`n")) }

# Otwórz Notatnik i czekaj na zamknięcie
Start-Process -FilePath "notepad.exe" -ArgumentList $fullKeyPath -Wait
Write-Host "`n✔️ Zapisane? Uruchom teraz: .\fm-key-apply.ps1" -ForegroundColor Green
