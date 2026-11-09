import { usePage } from "@inertiajs/react"

import {
  formatLongDate as formatLongDateValue,
  formatLongDateInline as formatLongDateInlineValue,
  formatShortDate,
  formatShortDateTime,
} from "@/lib/dates"
import { formatMoney as formatMoneyValue } from "@/lib/money"

// Fechas e importes siguen el locale de la app, igual que los textos: si el día
// de mañana se agrega otro idioma, no hay que tocar los componentes. El formato
// de los importes está en lib/money.ts y el de las fechas en lib/dates.ts.
export const useFormatters = () => {
  const { locale } = usePage().props

  const formatMoney = (amount: number | string) =>
    formatMoneyValue(amount, locale)

  const formatLongDate = (date: string) => formatLongDateValue(date, locale)

  const formatLongDateInline = (date: string) =>
    formatLongDateInlineValue(date, locale)

  return {
    formatMoney,
    formatLongDate,
    formatLongDateInline,
    formatShortDate,
    formatShortDateTime,
  }
}
