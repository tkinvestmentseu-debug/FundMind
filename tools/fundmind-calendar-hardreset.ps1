param()
$calDir = Join-Path "D:\FundMind\app" "calendar"
$calPath = Join-Path $calDir "index.tsx"

New-Item -ItemType Directory -Force -Path $calDir | Out-Null

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
  const daysInMonth = useMemo(
    () => dayjs(`${ymd.y}-${String(ymd.m).padStart(2, '0')}-01`).daysInMonth(),
    [ymd.y, ymd.m]
  );
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
        <Text style={styles.title}>{t(lang, 'calendar')}</Text>
        <View style={styles.row}>
          <Text>{fmt(value)}</Text>
        </View>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: '#fff' },
  scroll: { padding: 16 },
  title: { fontSize: 20, fontWeight: '700', marginBottom: 8 },
  row: { flexDirection: 'row', marginTop: 12 }
});
"@ | Set-Content -Encoding UTF8 $calPath

Set-Location D:\FundMind
npx expo start --clear --port 8081 --host lan
