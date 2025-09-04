import { Link } from 'expo-router';
import { View, Text, StyleSheet } from 'react-native';
import { useAppStore } from '../store/app';
import { Button } from '../components/ui/Button';

export default function Home() {
  const hasOnboarded = useAppStore(s => s.hasOnboarded);
  const toggleTheme = useAppStore(s => s.toggleTheme);
  const theme = useAppStore(s => s.theme);

  if (!hasOnboarded) {
    return (<View style={styles.center}>
      <Text style={styles.title}>FundMind</Text>
      <Text style={styles.subtitle}>Zacznij od krótkiego wprowadzenia.</Text>
      <Link href="/onboarding" asChild><Button title="Przejdź do Onboarding" /></Link>
    </View>);
  }

  return (<View style={styles.center}>
    <Text style={styles.title}>FundMind — Home</Text>
    <Text style={styles.subtitle}>Twoje centrum finansów AI (MVP).</Text>
    <View style={{ height: 12 }} />
    <Link href="/settings" asChild><Button title="Ustawienia" /></Link>
    <View style={{ height: 8 }} />
    <Button title={Tryb: } onPress={toggleTheme} />
  </View>);
}

const styles = StyleSheet.create({
  center:{flex:1,alignItems:'center',justifyContent:'center',padding:24},
  title:{fontSize:28,fontWeight:'700'},
  subtitle:{fontSize:16,opacity:0.8,marginTop:8,textAlign:'center'}
});
