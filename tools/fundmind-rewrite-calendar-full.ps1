param()
$projectRoot = "D:\FundMind"
$calDir = Join-Path $projectRoot "app\calendar"
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

        {/* Data */}
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

        {/* Czas */}
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

        {/* Podsumowanie */}
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

Set-Location $projectRoot
npx expo start --clear --port 8081 --host lan
