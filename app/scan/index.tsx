import React from 'react';
import { View, Text, StyleSheet, Pressable } from 'react-native';
import { useRouter } from 'expo-router';
import { MaterialCommunityIcons } from '@expo/vector-icons';

export default function Scan() {
  const router = useRouter();
  return (
    <View style={styles.container}>
      <MaterialCommunityIcons name="scan-helper" size={64} color="#6D4AFF" />
      <Text style={styles.title}>Skan paragonu</Text>
      <Text style={styles.subtitle}>
        Szybkie dodawanie wydatków ze zdjęcia. (Placeholder)
      </Text>
      <Pressable onPress={() => router.back()} style={styles.btn}>
        <Text style={styles.btnText}>Wróć</Text>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex:1, alignItems:'center', justifyContent:'center', backgroundColor:'#F6F8FB', padding:16 },
  title: { fontSize:24, fontWeight:'900', color:'#0F172A', marginTop:12 },
  subtitle: { fontSize:14, color:'#6B7280', textAlign:'center', marginTop:6, lineHeight:20 },
  btn: { marginTop:18, paddingHorizontal:16, paddingVertical:10, borderRadius:12, backgroundColor:'#6D4AFF' },
  btnText: { color:'#fff', fontWeight:'700' }
});
