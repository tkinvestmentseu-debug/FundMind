import React from "react";
import { Pressable, Text, StyleSheet } from "react-native";
import { router } from "expo-router";
import MaterialCommunityIcons from "@expo/vector-icons/MaterialCommunityIcons";

export default function AIBanner() {
  return (
    <Pressable style={styles.container} onPress={() => router.push("/ai" as any)}>
      <MaterialCommunityIcons name={"robot-outline" as any} size={22} />
      <Text style={styles.label}>AI</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: { flexDirection: "row", alignItems: "center", gap: 8, padding: 12, borderRadius: 12, borderWidth: 1, borderColor: "#E6EDF2" },
  label: { fontSize: 16, fontWeight: "600" }
});
