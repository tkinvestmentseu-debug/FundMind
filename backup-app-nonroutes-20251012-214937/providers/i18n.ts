import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import * as Localization from "expo-localization";
import en_common from "../../locales/en/common.json";
import en_home from "../../locales/en/home.json";
import en_calendar from "../../locales/en/calendar.json";
import en_settings from "../../locales/en/settings.json";
import en_notifications from "../../locales/en/notifications.json";
import en_ocr from "../../locales/en/ocr.json";
import en_ai from "../../locales/en/ai.json";
import en_errors from "../../locales/en/errors.json";
import pl_common from "../../locales/pl/common.json";
import pl_home from "../../locales/pl/home.json";
import pl_calendar from "../../locales/pl/calendar.json";
import pl_settings from "../../locales/pl/settings.json";
import pl_notifications from "../../locales/pl/notifications.json";
import pl_ocr from "../../locales/pl/ocr.json";
import pl_ai from "../../locales/pl/ai.json";
import pl_errors from "../../locales/pl/errors.json";
const resources = {
  en: { common: en_common, home: en_home, calendar: en_calendar, settings: en_settings, notifications: en_notifications, ocr: en_ocr, ai: en_ai, errors: en_errors },
  pl: { common: pl_common, home: pl_home, calendar: pl_calendar, settings: pl_settings, notifications: pl_notifications, ocr: pl_ocr, ai: pl_ai, errors: pl_errors },
};
const deviceLang = (Localization.locale || "en").startsWith("pl") ? "pl" : "en";
i18n.use(initReactI18next).init({
  resources, lng: deviceLang, fallbackLng: "en",
  ns: ["common","home","calendar","settings","notifications","ocr","ai","errors"],
  defaultNS: "common", compatibilityJSON: "v3",
  interpolation: { escapeValue: false },
});
export default i18n;