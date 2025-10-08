import React, { createContext, useContext, useEffect, useMemo, useState } from "react";
import { Appearance, type ColorSchemeName } from "react-native";

export type ThemeMode = "system" | "light" | "dark";

export type Tokens = {
  bg: string;
  card: string;
  text: string;
  muted: string;
  border: string;
  tint: string;
  chipBg: string;
  chipActiveBg: string;
};

function computeTokens(scheme: "light" | "dark"): Tokens {
  if (scheme === "dark") {
    return {
      bg: "#0B1220",
      card: "#0F172A",
      text: "#E6EDF2",
      muted: "#94A3B8",
      border: "#1E293B",
      tint: "#60A5FA",
      chipBg: "#0F172A",
      chipActiveBg: "#111827",
    };
  }
  return {
    bg: "#FFFFFF",
    card: "#FFFFFF",
    text: "#111827",
    muted: "#6B7280",
    border: "#E6EDF2",
    tint: "#2563EB",
    chipBg: "#F1F5F9",
    chipActiveBg: "#E2E8F0",
  };
}

export type ThemeContextValue = {
  mode: ThemeMode;
  setMode: (m: ThemeMode) => void;
  scheme: "light" | "dark";
  tokens: Tokens;
};

const ThemeCtx = createContext<ThemeContextValue | undefined>(undefined);

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  const [mode, setMode] = useState<ThemeMode>("system");
  const [sys, setSys] = useState<ColorSchemeName>(Appearance.getColorScheme());

  useEffect(() => {
    const sub = Appearance.addChangeListener(({ colorScheme }) => setSys(colorScheme));
    return () => sub.remove();
  }, []);

  const scheme: "light" | "dark" = useMemo(() => {
    if (mode === "light") return "light";
    if (mode === "dark") return "dark";
    return sys === "dark" ? "dark" : "light";
  }, [mode, sys]);

  const tokens = useMemo(() => computeTokens(scheme), [scheme]);

  const value = useMemo<ThemeContextValue>(() => ({ mode, setMode, scheme, tokens }), [mode, scheme, tokens]);

  return <ThemeCtx.Provider value={value}>{children}</ThemeCtx.Provider>;
}

// alias dla istniejącego kodu
export const AppThemeProvider = ThemeProvider;

export function useThemeMode(): ThemeContextValue {
  const ctx = useContext(ThemeCtx);
  if (!ctx) throw new Error("useThemeMode must be used within ThemeProvider");
  return ctx;
}

export function useColorTokens(): Tokens {
  return useThemeMode().tokens;
}

export function getStatusBarStyle(scheme: "light" | "dark"): "light" | "dark" {
  return scheme === "dark" ? "light" : "dark";
}

/** Legacy alias – zachowuje stary kształt API: const { colors } = useTokens() */
export function useTokens(): { colors: Tokens } & Tokens {
  // użyj systemowego schematu jak w starym kodzie:
  // jeśli w pliku jest już jakaś logika kolorów, weź istniejące Tokens; tu fallback prosty.
  const scheme = (typeof window === 'undefined'
    ? undefined
    : (require("react-native").Appearance?.getColorScheme?.() ?? undefined)) === 'dark' ? 'dark' : 'light';

  const colors: Tokens = (function(){
    // spróbuj odczytać z ewentualnych helperów; jeżeli ich nie ma, fallback:
    try {
      // jeśli plik ma computeTokens(scheme)
      // @ts-ignore
      if (typeof computeTokens === 'function') { return computeTokens(scheme); }
    } catch {}
    return {
      bg:    scheme === 'dark' ? "#0B1220" : "#FFFFFF",
      card:  scheme === 'dark' ? "#0F172A" : "#F8FAFC",
      text:  scheme === 'dark' ? "#E6EDF2" : "#0B1220",
      muted: scheme === 'dark' ? "#94A3B8" : "#6B7280",
      border:scheme === 'dark' ? "#1E293B" : "#E6EDF2",
      primary:"#2563EB",
      chipBg:        scheme === 'dark' ? "#0F172A" : "#F1F5F9",
      chipActiveBg:  scheme === 'dark' ? "#111827" : "#E2E8F0",
      tint: "#2563EB"
    } as Tokens;
  })();

  return { colors, ...colors };
}