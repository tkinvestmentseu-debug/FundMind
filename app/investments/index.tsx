import React from "react";

import { ThemedView as View, ThemedText as Text } from "../../src/ui/Themed";

import { Stack } from "expo-router";

export default function InvestmentsScreen() {
  return (
    <>
      <Stack.Screen options={{ title: "Kursy walut" }} />
      <View style={{ flex: 1, alignItems: "center", justifyContent: "center", padding: 24 }}>
        <Text testID="InvestmentsScreen-Title" style={{ fontSize: 22, fontWeight: "700" }}>Kursy walut</Text>
        <Text style={{ marginTop: 8, fontSize: 14 }}>Wkrotce: portfel, akcje, ETF, krypto.</Text>
      </View>
    </>
  );
}



