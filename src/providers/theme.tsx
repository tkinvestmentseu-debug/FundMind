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

function computeTokens(scheme: "light" | "dark"): Tokens {
  if (scheme === "dark") {
    return {
      bg: "#0B1220",
      card: "#111827",
      text: "#E5E7EB",
      muted: "#9CA3AF",
      border: "#1F2937",
      tint: "#3B82F6"
    };
  }
  return {
    bg: "#FFFFFF",
    card: "#F9FAFB",
    text: "#111827",
    muted: "#6B7280",
    border: "#E6EDF2",
    tint: "#2563EB"
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
    const sub = Appearance.addChangeListener(({ colorScheme }) => {
      setSys(colorScheme);
    });
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

export function useThemeMode(): ThemeContextValue {
  const ctx = useContext(ThemeCtx);
  if (!ctx) throw new Error("useThemeMode must be used within ThemeProvider");
  return ctx;
}

export function useColorTokens(): Tokens {
  const ctx = useContext(ThemeCtx);
  if (!ctx) throw new Error("useColorTokens must be used within ThemeProvider");
  return ctx.tokens;
}

export function getStatusBarStyle(scheme: "light" | "dark"): "light" | "dark" {
  return scheme === "dark" ? "light" : "dark";
}
