param([string]$RepoPath = (Get-Location).Path)
$ErrorActionPreference = 'Stop'
Set-Location $RepoPath
function Backup-File($p){ if(Test-Path $p){ Copy-Item $p "$p.bak-$(Get-Date -Format 'yyyyMMdd-HHmmss')" -Force } }
Write-Host "==> Instaluję paczki (AsyncStorage, SystemUI)" -ForegroundColor Cyan
npx expo install @react-native-async-storage/async-storage expo-system-ui | Out-Null
New-Item -ItemType Directory -Force -Path src\providers | Out-Null
New-Item -ItemType Directory -Force -Path src\ui | Out-Null
# --- src/providers/theme.tsx ---
$L = @(
import React, { createContext, useContext, useEffect, useMemo, useState } from "react";
import { useColorScheme } from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as SystemUI from "expo-system-ui";
import { StatusBar } from "expo-status-bar";
import { ThemeProvider as NavThemeProvider, DarkTheme as NavDark, DefaultTheme as NavLight, type Theme } from "@react-navigation/native";

type Mode = "light" | "dark" | "system";
type Tokens = { colors: {
  bg: string; card: string; cardElevated: string;
  text: string; textDim: string;
  primary: string; border: string;
  icon: string; iconDim: string;
  chipBg: string; chipActiveBg: string;
  tabBg: string;
} };

const light: Tokens["colors"] = {
  bg: "#F4F7FB",
  card: "#FFFFFF",
  cardElevated: "#FFFFFF",
  text: "#0F172A",
  textDim: "rgba(15,23,42,0.6)",
  primary: "#7C4DFF",
  border: "rgba(2,6,23,0.08)",
  icon: "#111827",
  iconDim: "rgba(17,24,39,0.5)",
  chipBg: "rgba(17,24,39,0.06)",
  chipActiveBg: "#2E2E2E",
  tabBg: "#FFFFFF",
};

const dark: Tokens["colors"] = {
  bg: "#0B0D12",
  card: "#141822",
  cardElevated: "#161B26",
  text: "#E5E7EB",
  textDim: "rgba(229,231,235,0.6)",
  primary: "#9D86FF",
  border: "rgba(229,231,235,0.08)",
  icon: "#E5E7EB",
  iconDim: "rgba(229,231,235,0.5)",
  chipBg: "rgba(229,231,235,0.12)",
  chipActiveBg: "#E5E7EB",
  tabBg: "#0F131C",
};

type Ctx = { mode: Mode; setMode: (m: Mode) => void; resolved: "light" | "dark"; tokens: Tokens };
const ThemeCtx = createContext<Ctx | null>(null);

export function AppThemeProvider({ children }: { children: React.ReactNode }) {
  const [mode, setMode] = useState<Mode>("system");
  const system = (useColorScheme() ?? "light") as "light" | "dark";
  const resolved = (mode === "system" ? system : mode) as "light" | "dark";

  useEffect(() => {
    AsyncStorage.getItem("fm:themeMode").then(v => {
      if (v === "light" || v === "dark" || v === "system") setMode(v as Mode);
    });
  }, []);
  useEffect(() => { AsyncStorage.setItem("fm:themeMode", mode).catch(()=>{}); }, [mode]);

  const tokens: Tokens = useMemo(() => ({ colors: resolved === "dark" ? dark : light }), [resolved]);
  useEffect(() => { SystemUI.setBackgroundColorAsync(tokens.colors.bg).catch(()=>{}); }, [tokens.colors.bg]);

  const navTheme: Theme = useMemo(() => {
    const base = resolved === "dark" ? NavDark : NavLight;
    return {
      ...base,
      colors: {
        ...base.colors,
        primary: tokens.colors.primary,
        background: tokens.colors.bg,
        card: tokens.colors.card,
        text: tokens.colors.text,
        border: tokens.colors.border,
        notification: tokens.colors.primary,
      },
    };
  }, [resolved, tokens]);

  const value: Ctx = { mode, setMode, resolved, tokens };

  return (
    <ThemeCtx.Provider value={value}>
      <NavThemeProvider value={navTheme}>
        <StatusBar style={resolved === "dark" ? "light" : "dark"} />
        {children}
      </NavThemeProvider>
    </ThemeCtx.Provider>
  );
}

export function useThemeMode() {
  const ctx = useContext(ThemeCtx);
  if (!ctx) throw new Error("useThemeMode must be used within AppThemeProvider");
  return { mode: ctx.mode, setMode: ctx.setMode, resolved: ctx.resolved };
}

export function useTokens() {
  const ctx = useContext(ThemeCtx);
  if (!ctx) throw new Error("useTokens must be used within AppThemeProvider");
  return ctx.tokens;
}
)
Set-Content src\providers\theme.tsx -Encoding UTF8 -Value $L
# --- src/ui/Themed.tsx ---
$L = @(
import React from "react";
import { View, Text, ScrollView, type ViewProps, type TextProps, type ScrollViewProps } from "react-native";
import { useTokens } from "../providers/theme";

export const ThemedView = React.forwardRef<View, ViewProps>((props, ref) => {
  const { colors } = useTokens();
  return <View ref={ref} {...props} style={[{ backgroundColor: colors.bg }, props.style]} />;
});
ThemedView.displayName = "ThemedView";

export const ThemedScrollView = React.forwardRef<ScrollView, ScrollViewProps>((props, ref) => {
  const { colors } = useTokens();
  return <ScrollView ref={ref} {...props} style={[{ backgroundColor: colors.bg }, props.style]} />;
});
ThemedScrollView.displayName = "ThemedScrollView";

export const ThemedText: React.FC<TextProps & { dim?: boolean }> = ({ style, dim, ...rest }) => {
  const { colors } = useTokens();
  return <Text {...rest} style={[{ color: dim ? colors.textDim : colors.text }, style]} />;
};

export function useColorTokens() {
  return useTokens().colors;
}
)
Set-Content src\ui\Themed.tsx -Encoding UTF8 -Value $L
# --- app/_layout.tsx (root) ---
if (Test-Path "app\_layout.tsx") { Backup-File "app\_layout.tsx" }
$L = @(
import React from "react";
import { Slot } from "expo-router";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { AppThemeProvider } from "../src/providers/theme";

export default function RootLayout() {
  return (
    <AppThemeProvider>
      <SafeAreaProvider>
        <Slot />
      </SafeAreaProvider>
    </AppThemeProvider>
  );
}
)
Set-Content app\_layout.tsx -Encoding UTF8 -Value $L
# --- app/(tabs)/_layout.tsx: kolory headera, tła scen i tab bara ---
$tabs = "app\(tabs)\_layout.tsx"
if (Test-Path $tabs) {
  $T = Get-Content $tabs -Raw
  if ($T -notmatch "src/ui/Themed") {
    $T = $T -replace "(from\s+""expo-router"";)", "$1`nimport { useColorTokens } from ""../../src/ui/Themed"";"
    $T = $T -replace "(export\s+default\s+function\s+[^\(]+\([^\)]*\)\s*\{)", "$1`n  const colors = useColorTokens();"
  }
  if ($T -match "<Tabs\s+screenOptions=\{\{") {
    $T = $T -replace "screenOptions=\{\{", "screenOptions={{ sceneContainerStyle: { backgroundColor: colors.bg }, headerStyle: { backgroundColor: colors.bg }, headerTitleStyle: { color: colors.text }, tabBarStyle: { backgroundColor: colors.tabBg, borderTopColor: colors.border }, tabBarActiveTintColor: colors.primary, tabBarInactiveTintColor: colors.icon, "
  } else {
    $T = $T -replace "<Tabs>", "<Tabs screenOptions={{ sceneContainerStyle: { backgroundColor: colors.bg }, headerStyle: { backgroundColor: colors.bg }, headerTitleStyle: { color: colors.text }, tabBarStyle: { backgroundColor: colors.tabBg, borderTopColor: colors.border }, tabBarActiveTintColor: colors.primary, tabBarInactiveTintColor: colors.icon }}>"
  }
  Backup-File $tabs
  Set-Content $tabs -Encoding UTF8 -Value $T
}
# --- Ustawienia: ThemedView + poprawny import hooka ---
$settings = "app\(tabs)\settings\index.tsx"
if (Test-Path $settings) {
  $S = Get-Content $settings -Raw
  if ($S -notmatch "src/ui/Themed") {
    $S = $S -replace "(import\s+React[^\n]*\n)", "$1import { ThemedView, ThemedText } from ""../../src/ui/Themed"";`n"
  }
  if ($S -match "useThemeMode") {
    $S = $S -replace "from\s+""[^""]*theme""", "from ""../../src/providers/theme"""
  }
  if ($S -match "<View\s+style=") {
    $S = $S -replace "<View\s+style=", "<ThemedView style=", 1
    $S = $S -replace "</View>", "</ThemedView>", 1
  }
  Backup-File $settings
  Set-Content $settings -Encoding UTF8 -Value $S
}
# --- .gitignore (idempotentnie) ---
if (-not (Test-Path ".gitignore")) { New-Item ".gitignore" -ItemType File | Out-Null }
$gi = Get-Content ".gitignore" -ErrorAction SilentlyContinue
$adds = @(".env",".env.*",".secrets/",".archive/","**/openai.key","tools/scan/")
foreach($a in $adds){ if ($gi -notcontains $a){ Add-Content ".gitignore" $a } }
Write-Host "`n==> Restart Metro (clear cache)" -ForegroundColor Cyan
npm run start -- -c
