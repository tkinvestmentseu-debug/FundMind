/** FundMind i18n bootstrap (idempotent) */
import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import * as Localization from "expo-localization";
import pl from "../../app/locales/pl.json";
import en from "../../app/locales/en.json";
const resources = { pl: { translation: pl }, en: { translation: en } } as const;
if (!i18n.isInitialized) {
  i18n.use(initReactI18next).init({
    compatibilityJSON: "v4",
    resources,
    lng: (Localization.getLocales?.()[0]?.languageCode as "pl" | "en") ?? "pl",
    fallbackLng: "pl",
    supportedLngs: ["pl","en"],
    interpolation: { escapeValue: false },
    returnNull: false,
    defaultNS: "translation",
  }).catch(() => {});
}
export default i18n;

