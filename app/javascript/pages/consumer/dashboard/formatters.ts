export const money = (value: number) => `$${Math.round(value)}`

export const weekday = (date: string) =>
  new Date(`${date}T12:00:00`)
    .toLocaleDateString("es-UY", { weekday: "short" })
    .replace(".", "")
    .slice(0, 3)

export const squish = (value: string) => value.trim().replace(/\s+/g, " ")

// Arma el texto igual que DeliveryAddress#full_address, que es con el que se
// compara la dirección elegida en el servidor.
export const fullAddress = (street: string, apartment: string) =>
  [squish(street), squish(apartment)].filter(Boolean).join(", ")
