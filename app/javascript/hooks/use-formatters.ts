import { usePage } from "@inertiajs/react"

// Fechas e importes siguen el locale de la app, igual que los textos: si el día
// de mañana se agrega otro idioma, no hay que tocar los componentes.
export const useFormatters = () => {
  const { locale } = usePage().props

  const formatMoney = (amount: number) =>
    new Intl.NumberFormat(locale, {
      style: "currency",
      currency: "UYU",
    }).format(amount)

  // Con el locale "es" un número de cuatro cifras no lleva punto de miles por
  // defecto, y el resumen por día tiene que verse "$2.400".
  const formatMoneyShort = (amount: number) => {
    const decimals = Number.isInteger(amount) ? 0 : 2

    return `$${new Intl.NumberFormat(locale, {
      minimumFractionDigits: decimals,
      maximumFractionDigits: decimals,
      useGrouping: "always",
    }).format(amount)}`
  }

  const formatDeliveryDate = (date: string) => {
    const formatted = new Intl.DateTimeFormat(locale, {
      weekday: "long",
      day: "numeric",
      month: "long",
    }).format(new Date(`${date}T00:00:00`))

    return formatted.charAt(0).toLocaleUpperCase(locale) + formatted.slice(1)
  }

  return { formatMoney, formatMoneyShort, formatDeliveryDate }
}
