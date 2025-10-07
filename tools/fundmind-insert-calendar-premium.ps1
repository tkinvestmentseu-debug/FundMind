param()
$projectRoot = "D:\FundMind"
Set-Location $projectRoot

# 1) zależności
npm install react-native-calendars @react-native-picker/picker dayjs

# 2) i18n
$i18nPath = Join-Path $projectRoot "app\_i18n.ts"
if (-not (Test-Path $i18nPath)) {
  @"
export type Lang = 'pl' | 'en';
export const t = (lang: Lang, key: string) => {
  const dict: Record<string, Record<string,string>> = {
    pl: { calendar:'Kalendarz',year:'Rok',month:'Miesiąc',day:'Dzień',hour:'Godzina',minute:'Minuta',selected:'Wybrano' },
    en: { calendar:'Calendar',year:'Year',month:'Month',day:'Day',hour:'Hour',minute:'Minute',selected:'Selected' }
  };
  const l = dict[lang] ?? dict['pl'];
  return l[key] ?? key;
};
"@ | Set-Content -Encoding UTF8 $i18nPath
}

# 3) premium calendar screen
$calDir = Join-Path $projectRoot "app\calendar"
New-Item -ItemType Directory -Force -Path $calDir | Out-Null
$calPath = Join-Path $calDir "index.tsx"

@"
import React, { useState } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Calendar, LocaleConfig } from 'react-native-calendars';
import { Picker } from '@react-native-picker/picker';
import dayjs from 'dayjs';
import { t, type Lang } from '../_i18n';
import { Stack } from 'expo-router';

export default function CalendarScreen() {
  const [lang, setLang] = useState<Lang>('pl');
  const [selectedDate, setSelectedDate] = useState<string>(dayjs().format('YYYY-MM-DD'));
  const [year, setYear] = useState<number>(dayjs().year());
  const [month, setMonth] = useState<number>(dayjs().month() + 1);
  const [day, setDay] = useState<number>(dayjs().date());
  const [hour, setHour] = useState<number>(dayjs().hour());
  const [minute, setMinute] = useState<number>(dayjs().minute());

  // configure locales
  LocaleConfig.locales['pl'] = {
    monthNames: ['Styczeń','Luty','Marzec','Kwiecień','Maj','Czerwiec','Lipiec','Sierpień','Wrzesień','Październik','Listopad','Grudzień'],
    monthNamesShort: ['Sty','Lut','Mar','Kwi','Maj','Cze','Lip','Sie','Wrz','Paź','Lis','Gru'],
    dayNames: ['Niedziela','Poniedziałek','Wtorek','Środa','Czwartek','Piątek','Sobota'],
    dayNamesShort: ['Nd','Pn','Wt','Śr','Czw','Pt','So']
  };
  LocaleConfig.locales['en'] = {
    monthNames: ['January','February','March','April','May','June','July','August','September','October','November','December'],
    monthNamesShort: ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'],
    dayNames: ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'],
    dayNamesShort: ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']
  };
  LocaleConfig.defaultLocale = lang;

  const years = Array.from({ length: 21 }, (_, i) => 2020 + i);
  const months = Array.from({ length: 12 }, (_, i) => i + 1);
  const daysInMonth = dayjs(`${year}-${String(month).padStart(2,'0')}-01`).daysInMonth();
  const days = Array.from({ length: daysInMonth }, (_, i) => i + 1);
  const hours = Array.from({ length: 24 }, (_, i) => i);
  const minutes = Array.from({ length: 60 }, (_, i) => i);

  return (
    <View style={styles.container}>
      <Stack.Screen options={{ title: t(lang,'calendar') }} />

      <Calendar
        current={selectedDate}
        onDayPress={d => {
          setSelectedDate(d.dateString);
          setYear(dayjs(d.dateString).year());
          setMonth(dayjs(d.dateString).month()+1);
          setDay(dayjs(d.dateString).date());
        }}
        markedDates={{
          [selectedDate]: { selected: true, marked: true }
        }}
      />

      <View style={styles.pickersRow}>
        <View style={styles.pickerBlock}>
          <Text>{t(lang,'year')}</Text>
          <Picker selectedValue={year} onValueChange={v => setYear(v)}>
            {years.map(y => <Picker.Item key={y} label={String(y)} value={y} />)}
          </Picker>
        </View>
        <View style={styles.pickerBlock}>
          <Text>{t(lang,'month')}</Text>
          <Picker selectedValue={month} onValueChange={v => setMonth(v)}>
            {months.map(m => <Picker.Item key={m} label={String(m)} value={m} />)}
          </Picker>
        </View>
        <View style={styles.pickerBlock}>
          <Text>{t(lang,'day')}</Text>
          <Picker selectedValue={day} onValueChange={v => setDay(v)}>
            {days.map(d => <Picker.Item key={d} label={String(d)} value={d} />)}
          </Picker>
        </View>
      </View>

      <View style={styles.pickersRow}>
        <View style={styles.pickerBlock}>
          <Text>{t(lang,'hour')}</Text>
          <Picker selectedValue={hour} onValueChange={v => setHour(v)}>
            {hours.map(h => <Picker.Item key={h} label={String(h)} value={h} />)}
          </Picker>
        </View>
        <View style={styles.pickerBlock}>
          <Text>{t(lang,'minute')}</Text>
          <Picker selectedValue={minute} onValueChange={v => setMinute(v)}>
            {minutes.map(min => <Picker.Item key={min} label={String(min)} value={min} />)}
          </Picker>
        </View>
      </View>

      <Text style={styles.selectedText}>
        {t(lang,'selected')}: {year}-{String(month).padStart(2,'0')}-{String(day).padStart(2,'0')} {String(hour).padStart(2,'0')}:{String(minute).padStart(2,'0')}
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex:1, padding:16 },
  pickersRow: { flexDirection:'row', justifyContent:'space-between', marginVertical:8 },
  pickerBlock: { flex:1, marginHorizontal:4 },
  selectedText: { marginTop:16, fontSize:16, textAlign:'center', fontWeight:'600' }
});
"@ | Set-Content -Encoding UTF8 $calPath

# 4) tabs patch
$tabsLayout = Join-Path $projectRoot "app\(tabs)\_layout.tsx"
if (Test-Path $tabsLayout) {
  $c = Get-Content $tabsLayout -Raw
  if ($c -notmatch "name='calendar'") {
    $c2 = $c -replace '(<Tabs>)', "`$1`r`n      <Tabs.Screen name='calendar' options={{ title: 'Kalendarz' }} />"
    $c2 | Set-Content -Encoding UTF8 $tabsLayout
  }
}

# 5) start expo
npx expo start --clear --port 8081 --host lan
