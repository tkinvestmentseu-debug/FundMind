import React from "react";
import { StyleSheet, Pressable } from "react-native";
import { ThemedText as Text } from "../../src/ui/Themed";

import { LinearGradient } from "expo-linear-gradient";

export default function GradientTile({ label, icon, onPress }) {
  return (
    <Pressable onPress={onPress} style={{ width: "80%", height: 120 }}>
      <LinearGradient
        colors={["#7C4DFF", "#5B9DFF"]}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.tile}
      >
        {icon}
        <Text style={styles.tileLabel}>{label}</Text>
      </LinearGradient>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  tile: {
    flex: 1,
    borderRadius: 20,
    justifyContent: "center",
    alignItems: "center",
    shadowColor: "#000",
    shadowOpacity: 0.15,
    shadowRadius: 8,
    elevation: 4,
  },
  tileLabel: {
    marginTop: 8,
    fontSize: 18,
    fontWeight: "700",
    color: "#fff",
  },
});
