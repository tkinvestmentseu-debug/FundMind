param()

$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }
$logFile = Join-Path $logDir ("fix-calendar-empty-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

function Log($msg) {
  Add-Content -Path $logFile -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $msg)
}

$calendarFile = Join-Path $projectRoot "app\calendar.tsx"
if (-not (Test-Path $calendarFile)) {
  $calendarFile = Join-Path $projectRoot "app\kalendarz.tsx"
}
if (-not (Test-Path $calendarFile)) {
  Log "Nie znaleziono pliku kalendarza."
  exit 1
}

$backupPath = $calendarFile + ".bak." + (Get-Date -Format "yyyyMMdd-HHmmss")
Copy-Item $calendarFile $backupPath -Force
Log "Backup zapisany: $backupPath"

$content = Get-Content $calendarFile -Raw

if ($content -match "Brak nadchodzących wydarzeń" -and $content -notmatch "lucide-react") {
  $importLine = "import { Calendar as CalendarIcon } from 'lucide-react-native';"
  if ($content -notmatch "lucide-react-native") {
    $content = $importLine + "`r`n" + $content
    Log "Dodano import ikony."
  }

  $content = $content -replace "Brak nadchodzących wydarzeń","<View style={{flexDirection: 'row', alignItems: 'center', marginTop: 8}}><CalendarIcon size={16} color='#6B7280' /><Text style={{color: '#6B7280', marginLeft: 6}}>Brak nadchodzących wydarzeń</Text></View>"
  Log "Podmieniono placeholder na ikonę + szary tekst."
} else {
  Log "Brak zmian (już poprawione?)."
}

Set-Content -Path $calendarFile -Value $content -Encoding UTF8
Log "Zapisano zmiany do $calendarFile"

Log "Fix gotowy."
