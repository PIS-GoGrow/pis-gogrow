// Formato único de fechas de toda la app, con dos variantes:
//   largo -> "Lunes 12 de octubre"  (día de la semana con mayúscula, mes en minúscula)
//            "lunes 12 de octubre"  (formatLongDateInline, para dentro de una frase)
//   corto -> "05/11/26"             (dd/mm/aa)
// Aparte, formatDateWithYear -> "11 de septiembre, 2026" (detalle de pedido del proveedor).
// Las fechas llegan del servidor como "YYYY-MM-DD" y se formatean sin pasar por
// la zona horaria del navegador, para que el día no se corra. El servidor arma
// los textos con el mismo criterio (DateFormat).
const ISO_DATE = /^(\d{4})-(\d{2})-(\d{2})/

export function formatLongDate(date: string, locale = "es-UY"): string {
  if (!ISO_DATE.test(date)) return ""

  const parsed = new Date(`${date.slice(0, 10)}T00:00:00Z`)
  if (Number.isNaN(parsed.getTime())) return ""

  // Intl escribe "lunes, 12 de octubre": se saca la coma y se pone la mayúscula.
  const text = new Intl.DateTimeFormat(locale, {
    weekday: "long",
    day: "numeric",
    month: "long",
    timeZone: "UTC",
  })
    .format(parsed)
    .replace(",", "")

  return text.charAt(0).toLocaleUpperCase(locale) + text.slice(1)
}

// La misma fecha larga con el día de la semana en minúscula, para usarla en medio
// de una frase: "Tu plato fue agregado al menú del lunes 12 de octubre".
export function formatLongDateInline(date: string, locale = "es-UY"): string {
  const text = formatLongDate(date, locale)

  return text.charAt(0).toLocaleLowerCase(locale) + text.slice(1)
}

export function formatDateWithYear(date: string, locale = "es-UY"): string {
  if (!ISO_DATE.test(date)) return ""

  const parsed = new Date(`${date.slice(0, 10)}T00:00:00Z`)
  if (Number.isNaN(parsed.getTime())) return ""

  const parts = new Intl.DateTimeFormat(locale, {
    day: "numeric",
    month: "long",
    year: "numeric",
    timeZone: "UTC",
  }).formatToParts(parsed)
  const part = (type: Intl.DateTimeFormatPartTypes) =>
    parts.find((item) => item.type === type)?.value

  return `${part("day")} de ${part("month")}, ${part("year")}`
}

export function formatShortDate(date: string): string {
  const match = ISO_DATE.exec(date)
  if (!match) return ""

  const [, year, month, day] = match
  return `${day}/${month}/${year.slice(2)}`
}

// Sin año, para los días de la lista de pedidos del proveedor: "10/09".
export function formatDayMonth(date: string): string {
  return formatShortDate(date).slice(0, 5)
}

// Para momentos exactos (un timestamp con zona): fecha corta y hora local.
export function formatShortDateTime(timestamp: string): string {
  const moment = new Date(timestamp)
  if (Number.isNaN(moment.getTime())) return ""

  const pad = (value: number) => String(value).padStart(2, "0")
  const date = `${pad(moment.getDate())}/${pad(moment.getMonth() + 1)}/${pad(
    moment.getFullYear() % 100,
  )}`

  return `${date} ${pad(moment.getHours())}:${pad(moment.getMinutes())}`
}
