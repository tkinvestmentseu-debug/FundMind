param()
$projectRoot = "D:\FundMind"
Set-Location $projectRoot

# 1) zależność
npm install react-native-calendars

# 2) i18n / LocaleConfig
$i18nPath = Join-Path $projectRoot "app\_i18n.ts"
if (-not (Test-Path $i18nPath)) {
  @"
export type Lang = 'pl' | 'en';
export const t = (lang: Lang, key: string) => {
  const dict: Record<string, Record<string,string>> = {
    pl: { calendar:'Kalendarz' },
    en: { calendar:'Calendar' }
  };
  const l = dict[lang] ?? dict['pl'];
  return l[key] ?? key;
};
"@ | Set-Content -Encoding UTF8 $i18nPath
}

# 3) nadpisz ekran calendar
$calDir = Join-Path $projectRoot "app\calendar"
New-Item -ItemType Directory -Force -Path $calDir | Out-Null
$calPath = Join-Path $calDir "index.tsx"

@"
import React, { useState } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Calendar, LocaleConfig } from 'react-native-calendars';
import { t, type Lang } from '../_i18n';
import { Stack } from 'expo-router';

export default function CalendarScreen() {
  const [lang, setLang] = useState<Lang>('pl');
  const [selectedDate, setSelectedDate] = useState<string>('');

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

  return (
    <View style={styles.container}>
      <Stack.Screen options={{ title: t(lang,'calendar') }} />
      <Calendar
        onDayPress={day => {
          setSelectedDate(day.dateString);
        }}
        markedDates={{
          [selectedDate]: { selected: true, marked: true }
        }}
      />
      {selectedDate ? <Text style={styles.selectedText}>{t(lang,'calendar')}: {selectedDate}</Text> : null}
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex:1, padding:16 },
  selectedText: { marginTop:16, fontSize:16, textAlign:'center' }
});
"@ | Set-Content -Encoding UTF8 $calPath

# 4) patch tabs layout
$tabsLayout = Join-Path $projectRoot "app\(tabs)\_layout.tsx"
if (Test-Path $tabsLayout) {
  $c = Get-Content $tabsLayout -Raw
  if ($c -notmatch "name='calendar'") {
    $c2 = $c -replace '(<Tabs>)', "`$1`r`n      <Tabs.Screen name='calendar' options={{ title: 'Kalendarz' }} />"
    $c2 | Set-Content -Encoding UTF8 $tabsLayout
  }
}

# 5) start expo clean
npx expo start --clear --port 8081 --host lan
