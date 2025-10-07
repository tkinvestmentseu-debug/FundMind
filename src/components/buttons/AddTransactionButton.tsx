import React from "react";
import { Pressable, Text, StyleSheet, View } from "react-native";

type Props = { onPress?: () => void };

export default function AddTransactionButton({ onPress }: Props) {
  return (
    <Pressable onPress={onPress} style={({ pressed }) => [styles.btn, pressed && styles.pressed]} accessibilityRole="button" testID="AddTransactionButton">
      <View style={styles.plus}><Text style={styles.plusText}>+</Text></View>
      <View style={{ flex: 1 }}>
        <Text style={styles.title}>Dodaj transakcje</Text>
        <Text style={styles.sub}>paragon, fakture, rachunek</Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  btn: {
    backgroundColor: "#1677FF",
    borderRadius: 24,
    minHeight: 64,
    paddingVertical: 14,
    paddingHorizontal: 16,
    flexDirection: "row",
    alignItems: "center",
    shadowColor: "#000000",
    shadowOpacity: 0.10,
    shadowRadius: 16,
    shadowOffset: { width: 0, height: 8 },
    elevation: 3
  },
  pressed: { opacity: 0.93 },
  plus: {
    width: 40, height: 40, borderRadius: 20,
    backgroundColor: "rgba(255,255,255,0.25)",
    alignItems: "center", justifyContent: "center",
    marginRight: 12
  },
  plusText: { color: "#FFFFFF", fontSize: 24, fontWeight: "700", lineHeight: 28 },
  title: { color: "#FFFFFF", fontSize: 18, fontWeight: "800" },
  sub:   { color: "rgba(255,255,255,0.95)", fontSize: 12, marginTop: 2 }
});
