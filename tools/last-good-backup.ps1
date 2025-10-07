import React, { createContext, useContext, useState } from "react";

type ThemeMode = "auto" | "light" | "dark";
type Lang = "pl" | "en";

interface SettingsContextType {
  themeMode: ThemeMode;
  setThemeMode: (mode: ThemeMode) => void;
  lang: Lang;
  setLang: (lang: Lang) => void;
}

const SettingsContext = createContext<SettingsContextType | undefined>(undefined);

export function SettingsProvider({ children }: { children: React.ReactNode }) {
  const [themeMode, setThemeMode] = useState<ThemeMode>("auto");
  const [lang, setLang] = useState<Lang>("pl");

  return (
    <SettingsContext.Provider value={{ themeMode, setThemeMode, lang, setLang }}>
      {children}
    </SettingsContext.Provider>
  );
}

export function useSettings() {
  const ctx = useContext(SettingsContext);
  if (!ctx) throw new Error("useSettings must be used inside SettingsProvider");
  return ctx;
}
