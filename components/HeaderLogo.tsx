import React from 'react';
import { View, Image, Text, StyleSheet } from 'react-native';
export default function HeaderLogo() {
  return (
    <View style={styles.wrap}>
      <Image source={require('../assets/fundmind-logo.png')} style={styles.logo} resizeMode="contain" />
    </View>
  );
}
const styles = StyleSheet.create({
  wrap: { alignItems: 'center', paddingTop: 4, marginBottom: 10 },
  logo: { width: 160, height: 38 }
});
