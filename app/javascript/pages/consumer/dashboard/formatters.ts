export const money = (value: number) => `$${Math.round(value)}`

export const weekday = (date: string) =>
  new Date(`${date}T12:00:00`)
    .toLocaleDateString("es-UY", { weekday: "short" })
    .replace(".", "")
    .slice(0, 3)
