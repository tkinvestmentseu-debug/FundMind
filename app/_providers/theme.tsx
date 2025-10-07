import React, { createContext, useContext, useEffect, useMemo, useState } from "react";
import { useColorScheme } from "react-native";
import AsyncStorage from "@react-native-async-storage/async-storage";
import { ThemeProvider, DarkTheme, DefaultTheme, Theme } from "@react-navigation/native";

type ThemeMode = "light" | "dark" | "system";

type Ctx = {
  themeMode: ThemeMode;
  setThemeMode: (m: ThemeMode) => void;
  effective: "light" | "dark";
};

const ThemeCtx = createContext<Ctx | null>(null);
const STORAGE_KEY = "app.themeMode";

export default function AppThemeProvider({ children }: { children: React.ReactNode }) {
  const system = useColorScheme(); // "light" | "dark" | null
  const [themeMode, setThemeMode] = useState<ThemeMode>("system");

  useEffect(() => {
    (async () => {
      try {
        const saved = await AsyncStorage.getItem(STORAGE_KEY);
        if (saved === "light" || saved === "dark" || saved === "system") setThemeMode(saved);
      } catch {}
    })();
  }, []);

  useEffect(() => { AsyncStorage.setItem(STORAGE_KEY, themeMode).catch(()=>{}); }, [themeMode]);

  const effective: "light" | "dark" =
    themeMode === "system" ? (system === "dark" ? "dark" : "light") : themeMode;

  const navTheme: Theme = effective === "dark" ? DarkTheme : DefaultTheme;

  const value = useMemo(() => ({ themeMode, setThemeMode, effective }), [themeMode, effective]);

  return (
    <ThemeCtx.Provider value={value}>
      <ThemeProvider value={navTheme}>{children}</ThemeProvider>
    </ThemeCtx.Provider>
  );
}

export function useThemeSettings() {
  const ctx = useContext(ThemeCtx);
  if (!ctx) throw new Error("useThemeSettings must be used within AppThemeProvider");
  return ctx;
}
