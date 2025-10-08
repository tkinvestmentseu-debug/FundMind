export type SettingsState = {
  language: "pl" | "en"; setLanguage: (l: "pl" | "en") => void;
  notifications: boolean; setNotifications: (v: boolean) => void;
  biometricLock: boolean; setBiometricLock: (v: boolean) => void;
  biometrics: boolean; setBiometrics: (v: boolean) => void;
  analyticsEnabled: boolean; setAnalyticsEnabled: (v: boolean) => void;
  analytics: boolean; setAnalytics: (v: boolean) => void;
  wifiOnlySync: boolean; setWifiOnlySync: (v: boolean) => void;
  currency: "PLN" | "USD" | "EUR"; setCurrency: (c: "PLN" | "USD" | "EUR") => void;
};
import React, { createContext, useContext, useEffect, useMemo, useState } from "react";
import AsyncStorage from "@react-native-async-storage/async-storage";

type Currency = "PLN" | "EUR" | "USD";
type Lang = "pl" | "en";

type Settings = {
  currency: Currency;
  notifications: boolean;
  biometrics: boolean;
  wifiOnly: boolean;
  language: Lang;
  analytics: boolean;
};

type Ctx = {
  settings: Settings;
  set: <K extends keyof Settings>(key: K, value: Settings[K]) => void;
  reset: () => void;
};

const DEF: Settings = {
  currency: "PLN",
  notifications: true,
  biometrics: false,
  wifiOnly: true,
  language: "pl",
  analytics: false
};

const KEY = "fundmind.settings.v1";
const CtxObj = createContext<Ctx | undefined>(undefined);

export function SettingsProvider({ children }: { children: React.ReactNode }) {
  const [settings, setSettings] = useState<Settings>(DEF);

  useEffect(() => {
    (async () => {
      try {
        const s = await AsyncStorage.getItem(KEY);
        if (s) {
          const parsed = JSON.parse(s) as Partial<Settings>;
          setSettings({ ...DEF, ...parsed });
        }
      } catch {}
    })();
  }, []);

  useEffect(() => {
    AsyncStorage.setItem(KEY, JSON.stringify(settings)).catch(() => {});
  }, [settings]);

  const api = useMemo<Ctx>(() => ({
    settings,
    set: (k, v) => setSettings(prev => ({ ...prev, [k]: v } as Settings)),
    reset: () => setSettings(DEF)
  }), [settings]);

  return <CtxObj.Provider value={api}>{children}</CtxObj.Provider>;
}

export function useSettings() {
  const ctx = useContext(CtxObj);
  if (!ctx) throw new Error("useSettings must be used within SettingsProvider");
  return ctx;
}
