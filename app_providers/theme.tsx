import React, { createContext, useContext, useMemo, useState } from "react";
import { useColorScheme } from "react-native";
import { DarkTheme, DefaultTheme, ThemeProvider } from "@react-navigation/native";

export type ThemeMode = "light" | "dark" | "system";
type Ctx = { mode: ThemeMode; setMode: (m: ThemeMode) => void; resolved: "light" | "dark" };

const ThemeModeContext = createContext<Ctx | undefined>(undefined);

export function AppThemeProvider({ children }: { children: React.ReactNode }) {
  const system = useColorScheme();
  const [mode, setMode] = useState<ThemeMode>("system");
  const resolved = mode === "system" ? (system ?? "light") : mode;
  const navTheme = resolved === "dark" ? DarkTheme : DefaultTheme;
  const value = useMemo(() => ({ mode, setMode, resolved }), [mode, resolved]);

  return (
    <ThemeModeContext.Provider value={value}>
      <ThemeProvider value={navTheme}>{children}</ThemeProvider>
    </ThemeModeContext.Provider>
  );
}

export function useThemeMode() {
  const ctx = useContext(ThemeModeContext);
  if (!ctx) throw new Error("useThemeMode must be used within AppThemeProvider");
  return ctx;
}
