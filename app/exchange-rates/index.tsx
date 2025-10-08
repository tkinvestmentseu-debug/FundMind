import React from "react";

import { ThemedView as View, ThemedText as Text } from "../src/ui/Themed";

import { Stack } from "expo-router";

export default function ExchangeRatesScreen() {
  return (
    <>
      <Stack.Screen options={{ title: "Kursy walut" }} />
      <View style={{ flex: 1, alignItems: "center", justifyContent: "center", padding: 24 }}>
        <Text testID="ExchangeRatesScreen-Title" style={{ fontSize: 22, fontWeight: "700" }}>Kursy walut</Text>
        <Text style={{ marginTop: 8, fontSize: 14 }}>Wkrotce: tabele i alerty walut.</Text>
      </View>
    </>
  );
}

