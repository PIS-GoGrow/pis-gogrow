import { describe, expect, it } from "vitest"

import {
  type Dish,
  NO_AGENDA,
  type Preview,
  type SavedMenu,
  canImport,
  entriesPayload,
  fromPreview,
  matchSaved,
  statusOf,
  summarize,
} from "@/lib/menu-import"

function preview(
  entries: Partial<Preview["entries"][number]>[] = [{}],
): Preview {
  return {
    id: "abc",
    filename: "menu.csv",
    error: null,
    entries: entries.map((entry, index) => ({
      number: index + 2,
      name: "Milanesa",
      description: "Con papas",
      price: 320,
      option_groups: [],
      errors: [],
      ...entry,
    })),
  }
}

function saved(...names: string[]): SavedMenu[] {
  return names.map((name, index) => ({
    id: index + 1,
    name,
    confirmed_orders: 0,
    agenda: NO_AGENDA,
  }))
}

function dish(values: Partial<Dish> = {}): Dish {
  return { ...fromPreview(preview())[0], ...values }
}

describe("fromPreview", () => {
  it("le da a cada tarjeta una identidad propia, que no es el número de fila", () => {
    const dishes = fromPreview(preview([{}, {}]))

    expect(dishes.map((d) => d.key)).toEqual(["abc-0", "abc-1"])
    expect(dishes.map((d) => d.number)).toEqual([2, 3])
  })

  it("deja el precio vacío cuando la planilla no lo trae", () => {
    expect(fromPreview(preview([{ price: null }]))[0].price).toBe("")
  })
})

describe("matchSaved", () => {
  it("cruza sin importar mayúsculas, tildes ni espacios de más", () => {
    expect(matchSaved("  ensalada cesar ", saved("Ensalada César"))?.id).toBe(1)
  })

  it("no cruza un nombre vacío", () => {
    expect(matchSaved("   ", saved("Milanesa"))).toBeNull()
  })
})

describe("statusOf", () => {
  it("marca como error la fila que la planilla no pudo leer", () => {
    expect(statusOf(dish({ errors: ["Falta el precio."] }), [])).toBe("error")
  })

  it("marca como ya existente el plato que coincide con uno guardado", () => {
    expect(statusOf(dish(), saved("Milanesa"))).toBe("exists")
  })

  it("lo pasa a nuevo cuando el proveedor elige duplicarlo", () => {
    expect(statusOf(dish({ action: "create" }), saved("Milanesa"))).toBe("new")
  })

  it("lo pasa a actualizado cuando elige actualizarlo", () => {
    expect(statusOf(dish({ action: "update" }), saved("Milanesa"))).toBe(
      "updated",
    )
  })

  it("pasa de nuevo a ya existente si al editarlo le pone el nombre de uno guardado", () => {
    expect(statusOf(dish({ name: "Tarta" }), saved("Milanesa"))).toBe("new")
    expect(statusOf(dish({ name: "Milanesa" }), saved("Milanesa"))).toBe(
      "exists",
    )
  })

  it("el error manda sobre todo lo demás", () => {
    expect(
      statusOf(dish({ action: "update", errors: ["Falta el precio."] }), []),
    ).toBe("error")
  })
})

describe("canImport", () => {
  it("no deja importar mientras haya un plato con error", () => {
    expect(canImport([dish(), dish({ errors: ["mal"] })], [])).toBe(false)
  })

  it("deja importar aunque haya platos que ya existen: esos se ignoran", () => {
    const dishes = [dish({ name: "Tarta" }), dish({ name: "Milanesa" })]

    expect(canImport(dishes, saved("Milanesa"))).toBe(true)
  })

  it("no deja importar si no quedó nada para crear ni actualizar", () => {
    expect(canImport([dish({ name: "Milanesa" })], saved("Milanesa"))).toBe(
      false,
    )
  })

  it("no deja importar una lista vacía", () => {
    expect(canImport([], [])).toBe(false)
  })
})

describe("summarize", () => {
  it("cuenta los platos por estado", () => {
    const dishes = [
      dish({ name: "Tarta" }),
      dish({ name: "Milanesa" }),
      dish({ name: "Sorrentinos", action: "update" }),
      dish({ errors: ["mal"] }),
    ]

    expect(summarize(dishes, saved("Milanesa"))).toEqual({
      new: 1,
      exists: 1,
      updated: 1,
      error: 1,
    })
  })
})

describe("entriesPayload", () => {
  it("deja afuera los platos que ya existen y no se decidieron", () => {
    const dishes = [dish({ name: "Tarta" }), dish({ name: "Milanesa" })]

    expect(
      entriesPayload(dishes, saved("Milanesa")).map((e) => e.name),
    ).toEqual(["Tarta"])
  })

  it("manda el plato duplicado como uno nuevo, sin id", () => {
    const dishes = [dish({ name: "Milanesa", action: "create" })]

    expect(entriesPayload(dishes, saved("Milanesa"))[0]).toMatchObject({
      action: "create",
      menu_id: null,
    })
  })

  it("manda el plato actualizado con el id del plato guardado", () => {
    const dishes = [dish({ name: "Milanesa", action: "update" })]

    expect(entriesPayload(dishes, saved("Milanesa"))[0]).toMatchObject({
      action: "update",
      menu_id: 1,
    })
  })

  it("le devuelve al plato actualizado la agenda que ya tenía", () => {
    const guardado = saved("Milanesa")
    guardado[0].agenda = {
      mode: "weekly",
      weekdays: [1, 3],
      date: null,
      starts_on: "2026-11-02",
      ends_on: null,
      amount: null,
    }

    const payload = entriesPayload(
      [dish({ name: "Milanesa", action: "update" })],
      guardado,
    )

    expect(payload[0].agenda).toEqual(guardado[0].agenda)
  })

  it("respeta la agenda que el proveedor eligió al editar el plato", () => {
    const agenda = {
      mode: "single" as const,
      weekdays: [2],
      date: "2026-11-03",
      starts_on: null,
      ends_on: null,
      amount: null,
    }

    const payload = entriesPayload([dish({ name: "Tarta", agenda })], [])

    expect(payload[0].agenda).toEqual(agenda)
  })

  it("crea sin programar el plato nuevo que nadie tocó", () => {
    expect(entriesPayload([dish({ name: "Tarta" })], [])[0].agenda).toEqual(
      NO_AGENDA,
    )
  })
})
