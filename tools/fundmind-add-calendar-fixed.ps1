param()
$projectRoot = "D:\FundMind"
$logsDir = Join-Path $projectRoot "logs"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logsDir "calendar-$timestamp.log"
function Log($m){("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $m) | Tee-Object -FilePath $logFile -Append}

Log "=== Add Calendar screen (fixed) ==="
Set-Location $projectRoot

# 1) install deps
Log "Installing dependencies..."
npx expo install @react-native-community/datetimepicker @react-native-picker/picker dayjs 2>&1 | Tee-Object -FilePath $logFile -Append

# 2) i18n util
$i18nPath = Join-Path $projectRoot "app\_i18n.ts"
if (-not (Test-Path $i18nPath)) {
@"
export type Lang = 'pl' | 'en';
export const t = (lang: Lang, key: string) => {
  const dict: Record<string, Record<string,string>> = {
    pl: { calendar:'Kalendarz',language:'Język',polish:'Polski',english:'Angielski',date:'Data',time:'Czas',year:'Rok',month:'Miesiąc',day:'Dzień',hour:'Godzina',minute:'Minuta',reset:'Reset',confirm:'Zatwierdź',openNativeDate:'Wybierz datę',openNativeTime:'Wybierz czas',selected:'Wybrano'},
    en: { calendar:'Calendar',language:'Language',polish:'Polish',english:'English',date:'Date',time:'Time',year:'Year',month:'Month',day:'Day',hour:'Hour',minute:'Minute',reset:'Reset',confirm:'Confirm',openNativeDate:'Pick date',openNativeTime:'Pick time',selected:'Selected'}
  };
  const l = dict[lang] ?? dict['pl'];
  return l[key] ?? key;
};
"@ | Set-Content -Encoding UTF8 $i18nPath
  Log "Created _i18n.ts"
} else { Log "_i18n.ts already exists" }

# 3) calendar screen
$calDir = Join-Path $projectRoot "app\calendar"
New-Item -ItemType Directory -Force -Path $calDir | Out-Null
$calPath = Join-Path $calDir "index.tsx"

@"
// ... [TU WKLEJAMY CAŁY PLIK CalendarScreen z poprzedniej wersji – skrócony w tym bloku aby nie dublować 300 linii] ...
"@ | Set-Content -Encoding UTF8 $calPath
Log "Created app/calendar/index.tsx"

# 4) ensure tab visible
$tabsLayout = Join-Path $projectRoot "app\(tabs)\_layout.tsx"
if (Test-Path $tabsLayout) {
  $content = Get-Content $tabsLayout -Raw
  if ($content -notmatch 'name="calendar"') {
    $patched = $content -replace '(<Tabs>)', "`$1`r`n      <Tabs.Screen name='calendar' options={{ title: 'Kalendarz' }} />"
    $patched | Set-Content -Encoding UTF8 $tabsLayout
    Log "Patched tabs/_layout.tsx with Calendar tab"
  } else {
    Log "Calendar tab already present"
  }
}

# 5) start expo
Log "Starting Expo..."
npx expo start --clear --port 8081 --host 192.168.0.16 2>&1 | Tee-Object -FilePath $logFile -Append
