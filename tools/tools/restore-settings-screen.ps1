import React from "react";
import { View, Text, Image, TouchableOpacity, StyleSheet, ScrollView } from "react-native";

const tiles = [
  { label: "Powiadomienia" },
  { label: "Bezpieczeństwo" },
  { label: "Konta" },
  { label: "Waluty" },
  { label: "Motyw" },
  { label: "O aplikacji" },
];

export default function SettingsScreen() {
  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Image source={require("../assets/fundmind-logo.png")} style={styles.logo} />
      <View style={styles.grid}>
        {tiles.map((tile, idx) => (
          <TouchableOpacity key={idx} style={styles.card} activeOpacity={0.8}>
            <Text style={styles.label}>{tile.label}</Text>
          </TouchableOpacity>
        ))}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    backgroundColor: "#FFFFFF",
    alignItems: "center",
    justifyContent: "flex-start",
    padding: 16,
  },
  logo: {
    width: 160,
    height: 160,
    resizeMode: "contain",
    marginBottom: 24,
  },
  grid: {
    flexDirection: "row",
    flexWrap: "wrap",
    justifyContent: "space-between",
  },
  card: {
    width: "47%",
    aspectRatio: 1,
    backgroundColor: "#FFFFFF",
    borderRadius: 16,
    borderWidth: 1,
    borderColor: "#E6EDF2",
    shadowColor: "#000",
    shadowOpacity: 0.05,
    shadowRadius: 4,
    shadowOffset: { width: 0, height: 2 },
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 16,
  },
  label: {
    fontSize: 16,
    fontWeight: "600",
    color: "#1A1A1A",
    textAlign: "center",
  },
});
