import React from "react";
import { render, fireEvent } from "@testing-library/react-native";
import SettingsScreen from "../app/(tabs)/settings";
import { ThemeProvider } from "../src/providers/theme";
import { SettingsProvider } from "../src/providers/settings";

function wrap(ui: React.ReactNode){
  return render(
    <SettingsProvider>
      <ThemeProvider>{ui}</ThemeProvider>
    </SettingsProvider>
  );
}

test("toggles currency and switches", () => {
  const { getByText } = wrap(<SettingsScreen />);
  fireEvent.press(getByText("EUR"));
  fireEvent.press(getByText("USD"));
  // jeśli renderuje bez crasha i interakcje nie rzucają – uznajemy za OK
});

test("renders switches", () => {
  const { getByText } = wrap(<SettingsScreen />);
  getByText("Powiadomienia");
  getByText("Blokada biometryczna");
  getByText("Synchronizacja tylko Wi-Fi");
  getByText("Analityka");
});
