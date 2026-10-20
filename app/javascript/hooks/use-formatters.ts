import { usePage } from "@inertiajs/react"

import { formatMoney as formatMoneyValue } from "@/lib/money"

// Fechas e importes siguen el locale de la app, igual que los textos: si el día
// de mañana se agrega otro idioma, no hay que tocar los componentes. El formato
// de los importes está en lib/money.ts.
export const useFormatters = () => {
  const { locale } = usePage().props

  const formatMoney = (amount: number) => formatMoneyValue(amount, locale)

  const formatDeliveryDate = (date: string) => {
    const formatted = new Intl.DateTimeFormat(locale, {
      weekday: "long",
      day: "numeric",
      month: "long",
    }).format(new Date(`${date}T00:00:00`))

    return formatted.charAt(0).toLocaleUpperCase(locale) + formatted.slice(1)
  }

  const formatLongDate = (date: string) =>
    new Intl.DateTimeFormat(locale, {
      day: "numeric",
      month: "long",
      year: "numeric",
    }).format(new Date(`${date}T00:00:00`))

  return { formatMoney, formatDeliveryDate, formatLongDate }
}
