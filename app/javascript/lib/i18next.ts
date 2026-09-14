import i18next from "i18next"
import { initReactI18next } from "react-i18next"

import es from "@/locales/es.json"

void i18next.use(initReactI18next).init({
  fallbackLng: "es",
  interpolation: {
    escapeValue: false, // React already escapes by default
    // Rails writes %{name} placeholders; keep one syntax on both sides.
    prefix: "%{",
    suffix: "}",
  },
  resources: {
    es: { translation: es.es },
  },
})

export default i18next
