import { Link } from 'expo-router';
import { View, Text, StyleSheet } from 'react-native';
import { Button } from '../../components/ui/Button';
import { useAppStore } from '../../store/app';

export default function Onboarding() {
  const setOnboarded = useAppStore(s => s.setOnboarded);
  return (<View style={styles.center}>
    <Text style={styles.h1}>Witaj w FundMind</Text>
    <Text style={styles.p}>Przejdziemy przez szybkie wprowadzenie i ustawienia startowe.</Text>
    <View style={{ height: 12 }} />
    <Link href="/" replace asChild><Button title="Zaczynamy" onPress={setOnboarded} /></Link>
  </View>);
}

const styles = StyleSheet.create({
  center:{flex:1,alignItems:'center',justifyContent:'center',padding:24},
  h1:{fontSize:26,fontWeight:'700',marginBottom:8},
  p:{fontSize:15,opacity:0.9,textAlign:'center'}
});
