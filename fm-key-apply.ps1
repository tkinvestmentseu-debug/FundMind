param(
  [string]$RepoPath             = "D:\FundMind",
  [string]$KeyFileRel           = ".secrets\openai.key",
  [string]$LegacyToolsFile      = "tools\openai-key.txt", # zgodność ze starymi skryptami
  [switch]$WriteLegacyToolsFile = $true,
  [switch]$WriteEnvLocal        = $true
)

$ErrorActionPreference = 'Stop'
Set-Location $RepoPath

# 1) Odczytaj klucz z pliku (pierwsza niepusta linia nie będąca komentarzem)
$fullKeyPath = Join-Path (Get-Location) $KeyFileRel
if (-not (Test-Path $fullKeyPath)) { throw "Brak pliku z kluczem: $fullKeyPath. Uruchom najpierw .\fm-key-open.ps1" }

$keyLine = (Get-Content -Path $fullKeyPath |
  Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne '' } |
  Select-Object -First 1).Trim()

if (-not $keyLine) { throw "Plik $KeyFileRel jest pusty. Wklej klucz i zapisz." }
if ($keyLine.Length -lt 20 -or $keyLine -notmatch '^sk-[A-Za-z0-9][A-Za-z0-9_\-]{10,}$') {
  throw "Wartość w $KeyFileRel nie wygląda na poprawny OpenAI API key (powinna zaczynać się od 'sk-')."
}

# 2) Pilnuj ignorowania sekretów
if (-not (Test-Path ".gitignore")) { New-Item ".gitignore" -ItemType File | Out-Null }
$giLines = Get-Content ".gitignore" -ErrorAction SilentlyContinue
$adds = @()
foreach ($rule in @(((Split-Path $KeyFileRel -Parent) + "/"), "**/openai-key.txt", ".env", ".env.*")) {
  if ($giLines -notcontains $rule) { $adds += $rule }
}
if ($adds.Count) {
  Add-Content ".gitignore" ("`n" + ($adds -join "`n"))
  git add .gitignore
  if (-not (git diff --cached --quiet)) {
    git commit -m "chore(security): ignore secrets (.env*, openai-key.txt, $KeyFileRel)"
  }
}

# 3) Zastosuj lokalnie (bez wypisywania klucza)
$env:OPENAI_API_KEY = $keyLine
setx OPENAI_API_KEY "$keyLine" | Out-Null

# 4) .env.local (dla narzędzi/node) – opcjonalnie
if ($WriteEnvLocal) {
  Set-Content -Path ".env.local" -Value "OPENAI_API_KEY=$keyLine" -Encoding UTF8
}

# 5) Plik kompatybilny dla starych skryptów (git-ignored) – opcjonalnie
if ($WriteLegacyToolsFile) {
  $legacyPath = Join-Path (Get-Location) $LegacyToolsFile
  New-Item -ItemType Directory -Force -Path (Split-Path $legacyPath -Parent) | Out-Null
  Set-Content -Path $legacyPath -Value $keyLine -NoNewline -Encoding ASCII
}

# 6) Sekret w GitHub (jeśli 'gh' dostępny i origin to GitHub)
$remoteUrl = git config --get remote.origin.url
$ownerRepo = $null
if ($remoteUrl -match 'github\.com[:/](.+?)/(.+?)(\.git)?$') {
  $ownerRepo = "$($Matches[1])/$($Matches[2])"
}
$ghOk = $false
try { gh --version *> $null; $ghOk = $true } catch {}

if ($ghOk -and $ownerRepo) {
  gh secret set OPENAI_API_KEY -R $ownerRepo -b "$keyLine"
} else {
  Write-Warning "Pominięto zapis sekretu do GitHub (brak 'gh' lub nie rozpoznano owner/repo)."
}

Write-Host "`n✅ Gotowe:" -ForegroundColor Green
Write-Host "• Ustawiono OPENAI_API_KEY (ta sesja + trwałe)."
Write-Host "• Utworzono/uzupełniono: .env.local i $LegacyToolsFile (oba ignorowane przez git)."
Write-Host "• Sekret OPENAI_API_KEY zapisany w GitHub (jeśli było możliwe)."
Write-Host "`nJeśli jakiś stary klucz mógł wyciec — unieważnij go w panelu OpenAI." -ForegroundColor Yellow
