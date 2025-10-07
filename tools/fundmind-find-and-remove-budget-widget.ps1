param(
  [switch]$DryRun,       # tylko wyszukaj i pokaż kontekst
  [switch]$StartMetro    # opcjonalny restart Metro (bez zmiany portu)
)

$ErrorActionPreference = "Stop"

function Log($m){ $ts = Get-Date -Format "HH:mm:ss"; Add-Content -Path $logFile -Value ("["+$ts+"] "+$m) }

$projectRoot = "D:\FundMind"
$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }
$logFile = Join-Path $logDir ("remove-widget-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

# Szukana fraza (unicode -> ASCII-escaped)
$phrase = [regex]::Unescape("Bud\u017Cet miesi\u0105ca")
$phraseAlt = "Bud(?:\u017C|z)et\s+miesi(?:\u0105|a)ca"

# 1) ZNAJDZ PLIK
$candidates = @()
Get-ChildItem -Path (Join-Path $projectRoot "app") -Recurse -Include *.tsx | ForEach-Object {
  $t = Get-Content $_.FullName -Raw
  if ($t -match $phraseAlt) {
    $score = 0
    if ($_.FullName -match "\\\(tabs\)\\index\.tsx$") { $score += 100 }
    if ($_.FullName -match "\\app\\index\.tsx$")      { $score += 80 }
    if ($_.FullName -match "index\.tsx$")             { $score += 10 }
    $candidates += [pscustomobject]@{ Path = $_.FullName; Score = $score; Length = $t.Length; Text = $t }
  }
}

if (-not $candidates) {
  Log "Nie znaleziono frazy 'Budzet miesiaca' w *.tsx"
  Write-Host "Nie znaleziono widzetu. Sprawdz czy tekst nie jest tlumaczony z i18n."
  exit 1
}

$candidates = $candidates | Sort-Object -Property @{Expression="Score";Descending=$true}, @{Expression="Length";Descending=$false}
$targetFile = $candidates[0].Path
$text = $candidates[0].Text
Log ("Wybrano plik: " + $targetFile)
Write-Host ("Plik z widzetem: " + $targetFile)

# Pokaż kontekst (10 linii przed/po)
$lines = $text -split "`r?`n"
$idx = -1
for ($i=0; $i -lt $lines.Length; $i++){ if ($lines[$i] -match $phraseAlt) { $idx = $i; break } }
if ($idx -ge 0) {
  $from = [Math]::Max(0, $idx-10); $to = [Math]::Min($lines.Length-1, $idx+10)
  Write-Host ("--- KONTEKST ("+$from+".."+$to+") ---")
  for ($j=$from; $j -le $to; $j++){ Write-Host ($j.ToString().PadLeft(4)+": "+$lines[$j]) }
  Write-Host ("-------------------------------")
}

if ($DryRun) { Log "Tryb DryRun - tylko wyszukiwanie."; exit 0 }

# 2) USUN CALY KONTENER
function Find-ClosingIdx([string[]]$arr, [int]$openIdx, [string]$tag){
  $depth = 0
  for ($j=$openIdx; $j -lt $arr.Length; $j++){
    if ($arr[$j] -match ("<" + [regex]::Escape($tag) + "\b")) { $depth++ }
    if ($arr[$j] -match ("</" + [regex]::Escape($tag) + ">\s*$")) { $depth-- }
    if ($depth -eq 0 -and $j -gt $openIdx) { return $j }
  }
  return -1
}

# znajdz najmniejszy kontener otwierajacy sie nad tytulem i zamykajacy po nim
$openRegex = "^\s*<(?<tag>Card|FMCard|LinearGradient|View|Pressable|TouchableOpacity|Surface|Paper)\b"

$idxPhrase = $idx
if ($idxPhrase -lt 0) { Log "Blad: nie znaleziono linii z fraza."; exit 2 }

$openIdx = -1; $openTag = $null; $closeIdx = -1
for ($i=$idxPhrase; $i -ge 0; $i--){
  $m = [regex]::Match($lines[$i], $openRegex)
  if ($m.Success){
    $tag = $m.Groups["tag"].Value
    $ci = Find-ClosingIdx -arr $lines -openIdx $i -tag $tag
    if ($ci -gt $idxPhrase){
      $openIdx = $i; $openTag = $tag; $closeIdx = $ci
      break
    }
  }
}
if ($openIdx -lt 0 -or $closeIdx -lt 0) {
  Log "Blad: nie znaleziono kontenera do usuniecia."
  Write-Host "Nie udalo sie jednoznacznie wyznaczyc bloku. Zerknij w kontekst powyzej."
  exit 3
}

# Backup
$backupPath = $targetFile + ".bak." + (Get-Date -Format "yyyyMMdd-HHmmss")
Copy-Item $targetFile $backupPath -Force
Log ("Backup: " + $backupPath)

# Wyciecie
$kept = @()
for ($k=0; $k -lt $lines.Length; $k++){
  if ($k -ge $openIdx -and $k -le $closeIdx) { continue }
  $kept += $lines[$k]
}
# Zwin nadmiarowe puste linie
$out = [string]::Join("`r`n", ($kept -join "`n") -split "(`r?`n){3,}" -join "`r`n`r`n")

# Weryfikacja: fraza nie moze zostac
if ($out -match $phraseAlt) {
  Log "Blad weryfikacji: fraza nadal wystepuje - przywracam backup."
  Copy-Item $backupPath $targetFile -Force
  exit 4
}

# Zapis
Set-Content -Path $targetFile -Value $out -Encoding UTF8
Log ("Zapisano zmiany do: " + $targetFile)
Write-Host "USUNIETO widzet. Plik: $targetFile"
Write-Host "Backup: $backupPath"
Write-Host "Log: $logFile"

# Opcjonalnie restart Metro (8081)
if ($StartMetro.IsPresent) {
  try {
    $conns = Get-NetTCPConnection -LocalPort 8081 -ErrorAction SilentlyContinue
    if ($conns) {
      $pids = $conns | Select-Object -ExpandProperty OwningProcess -Unique
      foreach($pid in $pids){ try { Stop-Process -Id $pid -Force } catch {} }
    }
    Set-Location $projectRoot
    Start-Process -FilePath "npx" -ArgumentList "expo start --clear --lan" -NoNewWindow
    Log "Metro restart triggered."
  } catch { Log ("Metro restart failed: " + $_.Exception.Message) }
}
