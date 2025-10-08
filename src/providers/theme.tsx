import React, { createContext, useContext, useEffect, useMemo, useState } from "react";
import { Appearance, ColorSchemeName } from "react-native";

export type ThemeMode = "light" | "dark" | "system";
export type Tokens = {
  bg: string;
  card: string;
  text: string;
  muted: string;
  border: string;
  tint: string;
};

function tokensFor(s: "light" | "dark"): Tokens {
  if (s === "dark") {
    return {
      bg: "#0B1220",
      card: "#121826",
      text: "#E7ECF4",
      muted: "#B3C0CF",
      border: "#263244",
      tint: "#8B7CFF",
    };
  }
  return {
    bg: "#FFFFFF",
    card: "#FFFFFF",
    text: "#0F172A",
    muted: "#64748B",
    border: "#E6EDF2",
    tint: "#6C5CE7",
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
  const scheme: "light" | "dark" = useMemo(
    () =>
      mode === "light" ? "light" : mode === "dark" ? "dark" : sys === "dark" ? "dark" : "light",
    [mode, sys],
  );
  const tokens = useMemo(() => tokensFor(scheme), [scheme]);
  const value = useMemo(() => ({ mode, setMode, scheme, tokens }), [mode, scheme, tokens]);
  return <ThemeCtx.Provider value={value}>{children}</ThemeCtx.Provider>;
}
export function useThemeMode(): ThemeContextValue {
  const c = useContext(ThemeCtx);
  if (!c) throw new Error("useThemeMode must be used within ThemeProvider");
  return c;
}
export function useColorTokens(): Tokens {
  const c = useContext(ThemeCtx);
  if (!c) throw new Error("useColorTokens must be used within ThemeProvider");
  return c.tokens;
}
export function getStatusBarStyle(s: "light" | "dark"): "light" | "dark" {
  return s === "dark" ? "light" : "dark";
}
