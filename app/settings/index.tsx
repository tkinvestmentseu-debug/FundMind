import { Link } from 'expo-router';
import { View, Text, StyleSheet, Switch } from 'react-native';
import { Button } from '../../components/ui/Button';
import { useAppStore } from '../../store/app';

export default function Settings() {
  const hasOnboarded = useAppStore(s => s.hasOnboarded);
  const setOnboarded = useAppStore(s => s.setOnboarded);
  const theme = useAppStore(s => s.theme);
  const setTheme = useAppStore(s => s.setTheme);

  return (<View style={styles.wrap}>
    <Text style={styles.h1}>Ustawienia</Text>
    <View style={styles.row}>
      <Text>Ukończony onboarding</Text>
      <Switch value={hasOnboarded} onValueChange={(v) => (v ? setOnboarded() : setOnboarded(false))} />
    </View>
    <View style={styles.row}>
      <Text>Motyw: {theme}</Text>
      <Button title="Przełącz motyw" onPress={() => setTheme(theme === "light" ? "dark" : "light")} />
    </View>
    <View style={{ height: 12 }} />
    <Link href="/" asChild><Button title="← Wróć" /></Link>
  </View>);
}

const styles = StyleSheet.create({
  wrap:{flex:1,padding:24,gap:16},
  h1:{fontSize:24,fontWeight:'700'},
  row:{flexDirection:'row',alignItems:'center',justifyContent:'space-between'}
});
