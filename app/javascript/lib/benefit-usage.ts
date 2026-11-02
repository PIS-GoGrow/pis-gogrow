export function formatBenefitMoney(amount: string): string {
  const match = /^(-?)(\d+)\.(\d{2})$/.exec(amount)
  if (!match) throw new Error("Invalid decimal amount")
  const [, sign, whole, cents] = match
  const grouped = new Intl.NumberFormat("es-UY", {
    useGrouping: "always",
  }).format(BigInt(whole))
  const negative = sign && (BigInt(whole) !== 0n || cents !== "00") ? "-" : ""
  return `${negative}$${grouped},${cents}`
}

export function formatBenefitMonth(month: string): string {
  const [year, number] = month.split("-")
  const date = new Date(0)
  date.setUTCFullYear(Number(year), Number(number) - 1, 1)
  return new Intl.DateTimeFormat("es-UY", {
    month: "long",
    year: "numeric",
    timeZone: "UTC",
  }).format(date)
}
