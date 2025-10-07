param()

$ErrorActionPreference = "Stop"
$projectRoot = "D:\FundMind"
$calendarFile = Join-Path $projectRoot "app\calendar.tsx"
$logDir = Join-Path $projectRoot "logs"
if (-not (Test-Path $logDir)) { New-Item -Path $logDir -ItemType Directory | Out-Null }
$logFile = Join-Path $logDir ("fix-calendar-icon-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".log")

function Log($msg) {
  Add-Content -Path $logFile -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $msg)
}

if (-not (Test-Path $calendarFile)) {
  Log "Nie znaleziono pliku app\\calendar.tsx"
  exit 1
}

# backup
$backupPath = $calendarFile + ".bak." + (Get-Date -Format "yyyyMMdd-HHmmss")
Copy-Item $calendarFile $backupPath -Force
Log "Backup zapisany: $backupPath"

$content = Get-Content $calendarFile -Raw

# dodanie importu ikony
if ($content -notmatch "lucide-react-native") {
  $importLine = "import { Calendar as CalendarIcon } from 'lucide-react-native';"
  $content = $importLine + "`r`n" + $content
  Log "Dodano import ikony."
}

# podmiana placeholdera
$pattern = "Brak nadchodzących wydarzeń"
$replacement = "<View style={{flexDirection: 'row', alignItems: 'center', marginTop: 8}}><CalendarIcon size={16} color='#6B7280' /><Text style={{color: '#6B7280', marginLeft: 6}}>Brak nadchodzących wydarzeń</Text></View>"
if ($content -match $pattern) {
  $content = $content -replace [regex]::Escape($pattern), [System.Text.RegularExpressions.Regex]::Escape($replacement) -replace "\\",""
  Log "Podmieniono placeholder na ikonę + szary tekst."
} else {
  Log "Nie znaleziono frazy do podmiany (może już poprawione?)."
}

Set-Content -Path $calendarFile -Value $content -Encoding UTF8
Log "Zapisano zmiany do $calendarFile"

# restart Metro
Set-Location $projectRoot
Log "Restart Metro..."
Start-Process -FilePath "npx" -ArgumentList "expo start --clear" -NoNewWindow
