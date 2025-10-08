import React from "react";
import { ThemeProvider, useThemeMode, useTokens } from "../src/providers/theme";
import { Slot } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context";
import { SettingsProvider } from "../src/providers/settings";

function Shell() {
  const { scheme } = useThemeMode();const { colors: t } = useTokens();return (
    <SafeAreaProvider>
      <SafeAreaView style={{ flex: 1, backgroundColor: t.bg }}>
        <StatusBar style={(scheme === 'dark' ? 'light' : 'dark')} />
        <Slot />
      </SafeAreaView>
    </SafeAreaProvider>
  );
}

export default function RootLayout() {
  return (
    <SettingsProvider>
      <ThemeProvider>
        <Shell />
      </ThemeProvider>
    </SettingsProvider>
  );
}
