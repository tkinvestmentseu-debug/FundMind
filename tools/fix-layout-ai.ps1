$layout = "D:\FundMind\app\_layout.tsx"
$ts = Get-Date -Format yyyyMMdd-HHmmss
Copy-Item $layout "$layout.bak.$ts" -Force

$code = @"
import { Tabs } from "expo-router";
import { View } from "react-native";
import React from "react";
import { SettingsProvider } from "../src/contexts/SettingsContext";
import AIBanner from "../components/AIBanner";

export default function RootLayout() {
  return (
    <SettingsProvider>
      <View style={{ flex: 1 }}>
        <Tabs
          screenOptions={{
            tabBarStyle: {
              position: "absolute",
              bottom: 72,   // 64px wysokość bannera + 8px odstępu
              left: 0,
              right: 0,
              height: 64,
            },
          }}
        />
        <AIBanner />
      </View>
    </SettingsProvider>
  );
}
"@

Set-Content -Path $layout -Value $code -Encoding UTF8
Write-Host "[fix-layout-ai] Plik $layout został zaktualizowany. Kopia w $layout.bak.$ts"
