import React from "react";
import { ThemedView as View, ThemedText as Text } from "../../../src/ui/Themed";
import { useColorTokens } from "../../../src/providers/theme";

export default function NotificationsScreen() {
  const t = useColorTokens();
  return (
    <View
      variant="screen"
      style={{ flex: 1, alignItems: "center", justifyContent: "center", padding: 24 }}
    >
      <Text style={{ fontSize: 20, fontWeight: "800", marginBottom: 6 }}>Powiadomienia</Text>
      <Text dim>Brak nowych alertów.</Text>
    </View>
  );
}
