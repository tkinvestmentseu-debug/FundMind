import React, { useEffect, useMemo, useState } from "react";
import i18n from "../../src/lib/i18n";
let useSettings: undefined | (() => { language?: "pl" | "en" }) = undefined;
try { useSettings = require("../../src/contexts/SettingsContext").useSettings; } catch {}

type Props = { children?: React.ReactNode };

export default function I18nGate({ children }: Props) {
  const langFromSettings = (() => {
    try { return useSettings ? (useSettings().language as "pl" | "en" | undefined) : undefined; } catch { return undefined }
  })();
  const lang = (langFromSettings || (i18n.language as "pl" | "en") || "pl") as "pl" | "en";

  // klucz wymusza REMOUNT całego subtree => 100% odświeżenia napisów
  const [key, setKey] = useState<string>(lang);

  useEffect(() => {
    const next = (lang || "pl") as "pl" | "en";
    if (i18n.language !== next) {
      try { i18n.reloadResources(); } catch {}
      i18n.changeLanguage(next).finally(() => setKey(next));
    } else {
      setKey(next);
    }
  }, [lang]);

  // remount – absolutna gwarancja spójności języka w całej aplikacji
  return <React.Fragment key={key}>{children ?? null}</React.Fragment>;
}
