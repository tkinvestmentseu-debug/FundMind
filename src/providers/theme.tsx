import * as React from "react";
import { useColorScheme } from "react-native";

export type ThemeMode = "system" | "light" | "dark";

export type ThemeCtx = {
  mode: ThemeMode;
  setMode: (m: ThemeMode) => void;
  /** kalkulacja końcowego motywu */
  computedTheme: "light" | "dark";
  /** alias pod istniejący kod */
  resolved: "light" | "dark";
};

const Ctx = React.createContext<ThemeCtx | null>(null);

export const ThemeProvider: React.FC<React.PropsWithChildren<{}>> = ({ children }) => {
  const [mode, setMode] = React.useState<ThemeMode>("system");
  const system = useColorScheme();
  const computed = (mode === "system" ? (system ?? "light") : mode) as "light" | "dark";
  const value = React.useMemo(
    () => ({ mode, setMode, computedTheme: computed, resolved: computed }),
    [mode, computed]
  );
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
};

/** alias wymagany przez app/_layout.tsx */
export const AppThemeProvider = ThemeProvider;

export function useThemeMode(): ThemeCtx {
  const ctx = React.useContext(Ctx);
  if (!ctx) {
    const system = useColorScheme();
    const computed = (system ?? "light") as "light" | "dark";
    return { mode: "system", setMode: () => {}, computedTheme: computed, resolved: computed };
  }
  return ctx;
}

/** Kolorowe tokeny używane w UI */
export type Tokens = {
  bg: string;
  text: string;
  border: string;
  muted: string;
  primary: string;
  chipBg: string;
  chipActiveBg: string;
};

/** Zwraca { colors, …colors } tak, by działało: const { colors } = useTokens() */
export function useTokens(): { colors: Tokens } & Tokens {
  const system = useColorScheme();
  const dark = system === "dark";
  const colors: Tokens = {
    bg: dark ? "#0B1220" : "#FFFFFF",
    text: dark ? "#E6EDF2" : "#0B1220",
    border: dark ? "#1E293B" : "#E6EDF2",
    muted: dark ? "#94A3B8" : "#6B7280",
    primary: "#2563EB",
    chipBg: dark ? "#0F172A" : "#F1F5F9",
    chipActiveBg: dark ? "#111827" : "#E2E8F0",
  };
  return { colors, ...colors };
}