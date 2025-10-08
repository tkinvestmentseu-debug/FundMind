import * as React from "react";

export type Language = "pl" | "en";
export type Currency = "PLN" | "USD" | "EUR";

export type SettingsState = {
  language: Language; setLanguage: (l: Language) => void;

  notifications: boolean; setNotifications: (v: boolean) => void;

  /** główne pole + aliasy zgodne z istniejącym kodem */
  biometricLock: boolean; setBiometricLock: (v: boolean) => void;
  biometrics: boolean; setBiometrics: (v: boolean) => void;

  analyticsEnabled: boolean; setAnalyticsEnabled: (v: boolean) => void;
  analytics: boolean; setAnalytics: (v: boolean) => void;

  wifiOnlySync: boolean; setWifiOnlySync: (v: boolean) => void;

  currency: Currency; setCurrency: (c: Currency) => void;
};

const Ctx = React.createContext<SettingsState | null>(null);

export const SettingsProvider: React.FC<React.PropsWithChildren<{}>> = ({ children }) => {
  const [language, setLanguage] = React.useState<Language>("pl");
  const [notifications, setNotifications] = React.useState(true);

  const [biometricLock, setBiometricLock] = React.useState(false);
  const setBiometrics = (v: boolean) => setBiometricLock(v);
  const biometrics = biometricLock;

  const [analyticsEnabled, setAnalyticsEnabled] = React.useState(true);
  const setAnalytics = (v: boolean) => setAnalyticsEnabled(v);
  const analytics = analyticsEnabled;

  const [wifiOnlySync, setWifiOnlySync] = React.useState(false);

  const [currency, setCurrency] = React.useState<Currency>("PLN");

  const value: SettingsState = {
    language, setLanguage,
    notifications, setNotifications,
    biometricLock, setBiometricLock,
    biometrics, setBiometrics,
    analyticsEnabled, setAnalyticsEnabled,
    analytics, setAnalytics,
    wifiOnlySync, setWifiOnlySync,
    currency, setCurrency,
  };

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
};

export function useSettings(): SettingsState {
  const ctx = React.useContext(Ctx);
  if (!ctx) {
    // fallback bez providera (bezpieczne wartości domyślne)
    return {
      language: "pl", setLanguage: () => {},
      notifications: true, setNotifications: () => {},
      biometricLock: false, setBiometricLock: () => {},
      biometrics: false, setBiometrics: () => {},
      analyticsEnabled: true, setAnalyticsEnabled: () => {},
      analytics: true, setAnalytics: () => {},
      wifiOnlySync: false, setWifiOnlySync: () => {},
      currency: "PLN", setCurrency: () => {},
    };
  }
  return ctx;
}