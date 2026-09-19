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

  const formatDeliveryDate = (date: string) =>
    new Intl.DateTimeFormat(locale, {
      weekday: "long",
      day: "numeric",
      month: "long",
    }).format(new Date(`${date}T00:00:00`))

  return { formatMoney, formatDeliveryDate }
}
