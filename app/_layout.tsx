import React from "react";
import { Slot } from "expo-router";
import { StatusBar } from "expo-status-bar";
import { SafeAreaProvider, SafeAreaView } from "react-native-safe-area-context";
import { ThemeProvider, useThemeMode, getStatusBarStyle, useColorTokens } from "src/providers/theme";
import { SettingsProvider } from "src/providers/settings";

function Shell() {
  const { scheme } = useThemeMode();
  const t = useColorTokens();
  return (
    <SafeAreaProvider>
      <SafeAreaView style={{ flex: 1, backgroundColor: t.bg }}>
        <StatusBar style={getStatusBarStyle(scheme)} />
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

