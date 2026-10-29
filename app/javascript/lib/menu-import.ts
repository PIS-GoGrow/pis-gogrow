import { normalizeText } from "@/lib/normalize-text"
import type { ProviderMenuImportsNew } from "@/types"

export type Preview = NonNullable<ProviderMenuImportsNew["preview"]>

export type PreviewEntry = Preview["entries"][number]
export type SavedMenu = ProviderMenuImportsNew["saved_menus"][number]
export type Agenda = SavedMenu["agenda"]
export type OptionGroup = PreviewEntry["option_groups"][number]
export type ConfirmedOrders = "keep" | "reject"

export const NO_AGENDA: Agenda = {
  mode: "none",
  weekdays: [],
  date: null,
  starts_on: null,
  ends_on: null,
  amount: null,
}

// Qué va a pasar con una fila cuando se importe:
//
// - nuevo: se crea un plato.
// - error: falta algo para poder crearlo. Hay que corregirlo o quitarlo.
// - ya existe: el nombre coincide con un plato guardado y el proveedor todavía
//   no dijo qué hacer. Si no hace nada, la fila se ignora.
// - actualizado: eligió pisar el plato guardado con lo que trae la fila.
export type DishStatus = "new" | "error" | "exists" | "updated"

export interface Dish {
  // Identidad de la tarjeta, estable mientras el proveedor la edita. No es el
  // número de fila: duplicar una fila crea dos tarjetas de la misma fila.
  key: string
  number: number
  name: string
  description: string
  price: string
  option_groups: OptionGroup[]
  // La agenda que eligió al editar el plato. En null, un plato nuevo se crea
  // sin programar y uno actualizado conserva la que ya tenía.
  agenda: Agenda | null
  errors: string[]
  // Null mientras no haya decidido nada: es lo que distingue "ya existe" de
  // "nuevo" y permite volver atrás con "Reestablecer".
  action: "create" | "update" | null
  confirmed_orders: ConfirmedOrders
}

export function fromPreview(preview: Preview): Dish[] {
  return preview.entries.map((entry, index) => ({
    key: `${preview.id}-${index}`,
    number: entry.number,
    name: entry.name,
    description: entry.description,
    price: entry.price === null ? "" : String(entry.price),
    option_groups: entry.option_groups,
    agenda: null,
    errors: entry.errors,
    action: null,
    confirmed_orders: "keep",
  }))
}

// El plato guardado que se llama igual, sin importar mayúsculas, tildes ni
// espacios de más. Se busca por el nombre que la tarjeta tiene ahora: editarlo
// puede hacer que un plato nuevo pase a existente, o al revés.
export function matchSaved(name: string, saved: SavedMenu[]): SavedMenu | null {
  const key = normalizeText(name.trim())
  if (key === "") return null

  return saved.find((menu) => normalizeText(menu.name.trim()) === key) ?? null
}

export function statusOf(dish: Dish, saved: SavedMenu[]): DishStatus {
  if (dish.errors.length > 0) return "error"
  if (dish.action === "update") return "updated"
  if (dish.action === null && matchSaved(dish.name, saved)) return "exists"

  return "new"
}

export function summarize(dishes: Dish[], saved: SavedMenu[]) {
  const counts: Record<DishStatus, number> = {
    new: 0,
    error: 0,
    exists: 0,
    updated: 0,
  }
  dishes.forEach((dish) => (counts[statusOf(dish, saved)] += 1))

  return counts
}

// Un plato con error frena la importación entera: hay que corregirlo o quitarlo.
// Uno que ya existe no, porque sin decisión simplemente se ignora.
export function canImport(dishes: Dish[], saved: SavedMenu[]) {
  const counts = summarize(dishes, saved)

  return counts.error === 0 && counts.new + counts.updated > 0
}

export function entriesPayload(dishes: Dish[], saved: SavedMenu[]) {
  return dishes
    .filter((dish) => ["new", "updated"].includes(statusOf(dish, saved)))
    .map((dish) => {
      const match =
        dish.action === "update" ? matchSaved(dish.name, saved) : null

      return {
        action: match ? "update" : "create",
        menu_id: match?.id ?? null,
        name: dish.name,
        description: dish.description,
        price: dish.price,
        option_groups: dish.option_groups,
        // Sin agenda propia, actualizar le devuelve al plato la que ya tenía:
        // importar no es motivo para despublicarlo.
        agenda: dish.agenda ?? match?.agenda ?? NO_AGENDA,
        confirmed_orders: dish.confirmed_orders,
      }
    })
}
