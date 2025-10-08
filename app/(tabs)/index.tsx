import React from "react";
import {
  ThemedScrollView as ScrollView,
  ThemedText as Text,
  ThemedView as View,
} from "../../src/ui/Themed";
import Card from "../../src/ui/Card";

export default function HomeTab() {
  return (
    <ScrollView variant="screen" contentContainerStyle={{ padding: 16, gap: 16 }}>
      <View style={{ alignItems: "center", marginBottom: 4 }}>
        <Text style={{ fontSize: 20, fontWeight: "800" }}>FundMind</Text>
      </View>

      <Card>
        <Text style={{ fontWeight: "800", marginBottom: 6 }}>Dzisiejsze wydatki</Text>
        <Text style={{ fontSize: 18 }}>63.50 PLN</Text>
      </Card>

      <Card>
        <Text style={{ fontWeight: "800", marginBottom: 6 }}>Nadchodzące</Text>
        <Text dim>Rata kredytu – jutro 10:00</Text>
        <Text dim>Faktura #102 – pt 14:00</Text>
        <Text dim>Wizyta u dentysty – pn 09:30</Text>
      </Card>

      {/* TODO: tu dodaj siatkę kolejnych Cardów / kafelków, bez jasnego tła ekranu */}
    </ScrollView>
  );
}
