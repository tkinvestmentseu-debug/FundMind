import React from 'react';
import { Pressable, StyleSheet, Platform } from "react-native";
import { ThemedView as View, ThemedText as Text } from "../../src/ui/Themed";

import { LinearGradient } from "expo-linear-gradient";

/**
 * Final 3x3:
 * - Dokładnie 3 kolumny dzięki procentowej szerokości + space-between w gridzie.
 * - Kompaktowy rozmiar: mniejsze badge/label, ale czytelnie.
 */
type TileProps = {
  label: string;
  icon: React.ReactElement;
  onPress: () => void;
};

export default function PremiumTile({ label, icon, onPress }: TileProps) {
  return (
    <Pressable
      onPress={onPress}
      style={({ pressed }) => [styles.tile, pressed && styles.tilePressed]}
      testID={`tile-${label}`}
    >
      <View style={styles.badgeShadow}>
        <LinearGradient
          colors={["#F4F1FF", "#EEEAFE"]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={styles.badge}
        >
          {icon}
        </LinearGradient>
      </View>

      <Text style={styles.label} numberOfLines={2} ellipsizeMode="tail">
        {label}
      </Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  // 3 kolumny: width = ~30.8% + space-between w gridzie ⇒ równe odstępy
  tile: {
    width: "30.8%",
    aspectRatio: 1,        // kwadrat
    borderRadius: 16,
    
    alignItems: "center",
    justifyContent: "center",
    marginBottom: 12,      // odstęp pionowy między wierszami
    borderWidth: 1,
    borderColor: "#E6EDF2",
    shadowColor: "#000",
    shadowOpacity: 0.05,
    shadowRadius: 7,
    shadowOffset: { width: 0, height: 3 },
    ...(Platform.OS === "android" ? { elevation: 2 } : {})
  },
  tilePressed: {
    shadowOpacity: 0.10,
    transform: [{ scale: 0.985 }]
  },
  badgeShadow: {
    marginBottom: 6,
    shadowColor: "#7C4DFF",
    shadowOpacity: 0.10,
    shadowRadius: 6,
    shadowOffset: { width: 0, height: 4 }
  },
  badge: {
    width: 42,
    height: 42,
    borderRadius: 21,
    alignItems: "center",
    justifyContent: "center",
    borderWidth: 1,
    borderColor: "rgba(124,77,255,0.14)",
    backgroundColor: "#F6F3FF"
  },
  label: {
    fontSize: 13,          // MNIEJSZY tekst
    fontWeight: "600",
    color: "#0F172A",
    textAlign: "center",
    lineHeight: 16,
    paddingHorizontal: 4
  }
});





