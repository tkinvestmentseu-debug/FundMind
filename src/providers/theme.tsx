import React, { createContext, useContext, useEffect, useMemo, useState } from "react";
import { Appearance, ColorSchemeName } from "react-native";

export type ThemeMode = "light" | "dark" | "system";
export type Tokens = { bg:string; card:string; text:string; muted:string; border:string; tint:string; };

function tokensFor(s: "light" | "dark"): Tokens {
  return s === "dark"
    ? { bg:"#0B1220", card:"#111827", text:"#E5E7EB", muted:"#9CA3AF", border:"#1F2937", tint:"#7C8CFF" }
    : { bg:"#FFFFFF", card:"#FFFFFF", text:"#0F172A", muted:"#64748B", border:"#E6EDF2", tint:"#6C5CE7" };
}

export type ThemeContextValue = { mode:ThemeMode; setMode:(m:ThemeMode)=>void; scheme:"light"|"dark"; tokens:Tokens; };
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

  const tokens = useMemo(() => tokensFor(scheme), [scheme]);
  const value = useMemo(() => ({ mode, setMode, scheme, tokens }), [mode, scheme, tokens]);

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
export function getStatusBarStyle(s: "light" | "dark"): "light" | "dark" {
  return s === "dark" ? "light" : "dark";
}
