import React from "react";
import { SafeAreaView, StyleSheet } from "react-native";
import { ThemedText as Text } from "../../../src/ui/Themed";

import { MaterialCommunityIcons } from "@expo/vector-icons";

// Premium design for Notifications screen
export default function NotificationsScreen() {
  return (
    <SafeAreaView style={styles.container}>
      <MaterialCommunityIcons name="bell" size={80} color="#7C4DFF" style={styles.icon} />
      <Text style={styles.title}>Powiadomienia</Text>
      <Text style={styles.subtitle}>Brak nowych alertów.</Text>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: "center",
    alignItems: "center",
    backgroundColor: "#F7F9FC",
    padding: 20,
  },
  icon: {
    marginBottom: 24,
  },
  title: {
    fontSize: 28,
    fontWeight: "700",
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: "#7C8A96",
  },
});


