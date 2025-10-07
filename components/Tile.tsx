import React from "react";
import { TouchableOpacity, View, Text, StyleSheet } from "react-native";
import { LucideIcon } from "lucide-react-native";

type TileProps = {
  label: string;
  icon: LucideIcon;
  onPress?: () => void;
};

export default function Tile({ label, icon: Icon, onPress }: TileProps) {
  return (
    <TouchableOpacity style={styles.card} onPress={onPress}>
      <Icon size={32} color="#1E1E1E" />
      <Text style={styles.label}>{label}</Text>
    </TouchableOpacity>
  );
}

const styles = StyleSheet.create({
  card: {
    flex: 1,
    aspectRatio: 1,
    margin: 8,
    borderRadius: 16,
    backgroundColor: "#fff",
    justifyContent: "center",
    alignItems: "center",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 6,
    elevation: 2,
  },
  label: {
    marginTop: 6,
    fontSize: 14,
    fontWeight: "600",
    textAlign: "center",
  },
});

