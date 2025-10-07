param()
$projectRoot = "D:\FundMind"
$logsDir = Join-Path $projectRoot "logs"
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $logsDir "calendar-$timestamp.log"
function Log($m){("[{0}] {1}" -f (Get-Date -Format "HH:mm:ss"), $m) | Tee-Object -FilePath $logFile -Append}

Log "=== Add Calendar screen ==="
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
import React, { useMemo, useState } from 'react';
import { View, Text, Pressable, Platform, StyleSheet, ScrollView } from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import { Picker } from '@react-native-picker/picker';
import dayjs from 'dayjs';
import { t, type Lang } from '../_i18n';
import { Stack } from 'expo-router';

const YEARS_BACK = 80;
const YEARS_FWD = 20;

export default function CalendarScreen() {
  const [lang, setLang] = useState<Lang>('pl');
  const [value, setValue] = useState(new Date());
  const [showDate, setShowDate] = useState(false);
  const [showTime, setShowTime] = useState(false);

  const ymd = useMemo(() => ({
    y: value.getFullYear(),
    m: value.getMonth() + 1,
    d: value.getDate(),
    hh: value.getHours(),
    mm: value.getMinutes()
  }), [value]);

  const years = useMemo(() => {
    const now = new Date().getFullYear();
    const arr: number[] = [];
    for (let y = now - YEARS_BACK; y <= now + YEARS_FWD; y++) arr.push(y);
    return arr;
  }, []);
  const months = Array.from({ length: 12 }, (_, i) => i + 1);
  const daysInMonth = useMemo(() => dayjs(`${ymd.y}-${String(ymd.m).padStart(2, '0')}-01`).daysInMonth(), [ymd.y, ymd.m]);
  const days = Array.from({ length: daysInMonth }, (_, i) => i + 1);
  const hours = Array.from({ length: 24 }, (_, i) => i);
  const minutes = Array.from({ length: 60 }, (_, i) => i);

  const apply = (p: Partial<{ y: number; m: number; d: number; hh: number; mm: number }>) => {
    const d = new Date(value);
    if (p.y !== undefined) d.setFullYear(p.y);
    if (p.m !== undefined) d.setMonth(p.m - 1);
    if (p.d !== undefined) d.setDate(p.d);
    if (p.hh !== undefined) d.setHours(p.hh);
    if (p.mm !== undefined) d.setMinutes(p.mm);
    setValue(d);
  };

  const fmt = (d: Date) => dayjs(d).format('YYYY-MM-DD HH:mm');

  return (
    <View style={styles.container}>
      <Stack.Screen options={{ title: t(lang, 'calendar') }} />
      <ScrollView contentContainerStyle={styles.scroll}>
        <View style={styles.header}>
          <Text style={styles.title}>{t(lang, 'calendar')}</Text>
          <View style={styles.langRow}>
            <Text style={styles.label}>{t(lang, 'language')}:</Text>
            <View style={styles.pickerWrap}>
              <Picker selectedValue={lang} onValueChange={(v) => setLang(v as Lang)}>
                <Picker.Item label={t(lang, 'polish')} value="pl" />
                <Picker.Item label={t(lang, 'english')} value="en" />
              </Picker>
            </View>
          </View>
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>{t(lang, 'date')}</Text>
          <View style={styles.row}>
            <View style={styles.pickerBlock}>
              <Text style={styles.pickerLabel}>{t(lang, 'year')}</Text>
              <View style={styles.pickerWrap}>
                <Picker selectedValue={ymd.y} onValueChange={(v) => apply({ y: Number(v) })}>
                  {years.map(y => <Picker.Item key={y} label={String(y)} value={y} />)}
                </Picker>
              </View>
            </View>
            <View style={styles.pickerBlock}>
              <Text style={styles.pickerLabel}>{t(lang, 'month')}</Text>
              <View style={styles.pickerWrap}>
                <Picker selectedValue={ymd.m} onValueChange={(v) => apply({ m: Number(v) })}>
                  {months.map(m => <Picker.Item key={m} label={String(m).padStart(2, '0')} value={m} />)}
                </Picker>
              </View>
            </View>
            <View style={styles.pickerBlock}>
              <Text style={styles.pickerLabel}>{t(lang, 'day')}</Text>
              <View style={styles.pickerWrap}>
                <Picker selectedValue={Math.min(ymd.d, daysInMonth)} onValueChange={(v) => apply({ d: Number(v) })}>
                  {days.map(d => <Picker.Item key={d} label={String(d).padStart(2, '0')} value={d} />)}
                </Picker>
              </View>
            </View>
          </View>
          <Pressable style={styles.button} onPress={() => setShowDate(true)}>
            <Text style={styles.buttonText}>{t(lang, 'openNativeDate')}</Text>
          </Pressable>
          {showDate && (
            <DateTimePicker
              value={value}
              mode="date"
              display={Platform.OS === 'ios' ? 'spinner' : 'default'}
              onChange={(_, d) => { setShowDate(false); if (d) setValue(d); }}
            />
          )}
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>{t(lang, 'time')}</Text>
          <View style={styles.row}>
            <View style={styles.pickerBlock}>
              <Text style={styles.pickerLabel}>{t(lang, 'hour')}</Text>
              <View style={styles.pickerWrap}>
                <Picker selectedValue={ymd.hh} onValueChange={(v) => apply({ hh: Number(v) })}>
                  {hours.map(h => <Picker.Item key={h} label={String(h).padStart(2, '0')} value={h} />)}
                </Picker>
              </View>
            </View>
            <View style={styles.pickerBlock}>
              <Text style={styles.pickerLabel}>{t(lang, 'minute')}</Text>
              <View style={styles.pickerWrap}>
                <Picker selectedValue={ymd.mm} onValueChange={(v) => apply({ mm: Number(v) })}>
                  {minutes.map(m => <Picker.Item key={m} label={String(m).padStart(2, '0')} value={m} />)}
                </Picker>
              </View>
            </View>
          </View>
          <Pressable style={styles.button} onPress={() => setShowTime(true)}>
            <Text style={styles.buttonText}>{t(lang, 'openNativeTime')}</Text>
          </Pressable>
          {showTime && (
            <DateTimePicker
              value={value}
              mode="time"
              display={Platform.OS === 'ios' ? 'spinner' : 'default'}
              onChange={(_, d) => { setShowTime(false); if (d) setValue(d); }}
            />
          )}
        </View>

        <View style={styles.card}>
          <Text style={styles.cardTitle}>{t(lang, 'selected')}</Text>
          <Text style={styles.value}>{fmt(value)}</Text>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  scroll: { padding: 16 },
  header: { marginBottom: 16 },
  title: { fontSize: 20, fontWeight: '700', marginBottom: 8 },
  langRow: { flexDirection: 'row', alignItems: 'center' },
  label: { fontSize: 14, marginRight: 8 },
  pickerWrap: { borderWidth: 1, borderColor: '#E6EDF2', borderRadius: 8, overflow: 'hidden' },
  row: { flexDirection: 'row', justifyContent: 'space-between' },
  card: { backgroundColor: '#fff', padding: 12, borderRadius: 12, marginBottom: 16, shadowColor: '#000', shadowOpacity: 0.05, shadowRadius: 4, elevation: 2 },
  cardTitle: { fontWeight: '600', marginBottom: 8 },
  pickerBlock: { flex: 1, marginHorizontal: 4 },
  pickerLabel: { fontSize: 12, marginBottom: 4 },
  button: { backgroundColor: '#007AFF', padding: 10, borderRadius: 8, marginTop: 8 },
  buttonText: { color: '#fff', textAlign: 'center', fontWeight: '600' },
  value: { fontSize: 16, fontWeight: '500', marginTop: 8 }
});
"@ | Set-Content -Encoding UTF8 $calPath
Log "Created app/calendar/index.tsx"

# 4) ensure tab visible
$tabsLayout = Join-Path $projectRoot "app\(tabs)\_layout.tsx"
if (Test-Path $tabsLayout) {
  $content = Get-Content $tabsLayout -Raw
  if ($content -notmatch "name=\"calendar\"") {
    $patched = $content -replace "(\<Tabs\>)","`$1`r`n      <Tabs.Screen name=\"calendar\" options={{ title: 'Kalendarz' }} />"
    $patched | Set-Content -Encoding UTF8 $tabsLayout
    Log "Patched tabs/_layout.tsx with Calendar tab"
  } else {
    Log "Calendar tab already present"
  }
}

# 5) start expo
Log "Starting Expo..."
npx expo start --clear --port 8081 --host 192.168.0.16 2>&1 | Tee-Object -FilePath $logFile -Append
