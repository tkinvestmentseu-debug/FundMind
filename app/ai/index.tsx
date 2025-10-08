import React from "react";
import { StyleSheet } from "react-native";
import { ThemedView as View, ThemedText as Text } from "../../src/ui/Themed";

export default function AiScreen() {
  return (
    <View variant="screen" style={styles.container}>
      <Text style={styles.title}>🤖 AI</Text>
      <Text>Witaj w asystencie AI.</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, alignItems: "center", justifyContent: "center", padding: 24 },
  title: { fontSize: 24, fontWeight: "700", marginBottom: 8 },
});
