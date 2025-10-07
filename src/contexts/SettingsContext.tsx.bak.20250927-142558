import React, { createContext, useContext, useState, useEffect } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";

type Theme = "light" | "dark" | "auto";
type Lang = "pl" | "en";

type SettingsContextType = {
  theme: Theme;
  setTheme: (t: Theme) => void;
  lang: Lang;
  setLang: (l: Lang) => void;
};

const SettingsContext = createContext<SettingsContextType | undefined>(undefined);

export function SettingsProvider({ children }: { children: React.ReactNode }) {
  const [theme, setThemeState] = useState<Theme>("auto");
  const [lang, setLangState] = useState<Lang>("pl");

  useEffect(() => {
    (async () => {
      const savedTheme = await AsyncStorage.getItem("theme");
      const savedLang = await AsyncStorage.getItem("lang");
      if (savedTheme) setThemeState(savedTheme as Theme);
      if (savedLang) setLangState(savedLang as Lang);
    })();
  }, []);

  const setTheme = (t: Theme) => {
    setThemeState(t);
    AsyncStorage.setItem("theme", t);
  };

  const setLang = (l: Lang) => {
    setLangState(l);
    AsyncStorage.setItem("lang", l);
  };

  return (
    <SettingsContext.Provider value={{ theme, setTheme, lang, setLang }}>
      {children}
    </SettingsContext.Provider>
  );
}

export function useSettings() {
  const ctx = useContext(SettingsContext);
  if (!ctx) throw new Error("useSettings must be used inside SettingsProvider");
  return ctx;
}
