// Formato único de importes de toda la app: símbolo "$" adelante, punto como
// separador de miles (siempre, también en cuatro cifras) y coma decimal.
// Los centésimos aparecen solo cuando el importe los tiene de verdad:
//   1250     -> "$1.250"
//   1250.5   -> "$1.250,50"
//   440.25   -> "$440,25"
// El servidor arma los textos con el mismo criterio (Account.format_amount).
export function formatMoney(amount: number | string, locale = "es-UY"): string {
  const numericAmount = typeof amount === "string" ? Number(amount) : amount
  if (isNaN(numericAmount)) return "$0"

  const cents = Math.round(Math.abs(numericAmount) * 100)
  const decimals = cents % 100 === 0 ? 0 : 2
  const sign = numericAmount < 0 && cents > 0 ? "-" : ""

  const number = new Intl.NumberFormat(locale, {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
    useGrouping: "always",
  }).format(cents / 100)

  return `${sign}$${number}`
}
