import { describe, expect, it } from "vitest"

import {
  formatLongDate,
  formatLongDateInline,
  formatShortDate,
  formatShortDateTime,
} from "./dates"

describe("formatLongDate", () => {
  it("escribe el día de la semana con mayúscula y el mes en minúscula", () => {
    expect(formatLongDate("2026-10-12")).toBe("Lunes 12 de octubre")
    expect(formatLongDate("2026-11-05")).toBe("Jueves 5 de noviembre")
  })

  it("no usa coma ni mayúsculas en el mes", () => {
    expect(formatLongDate("2026-10-20")).not.toContain(",")
    expect(formatLongDate("2026-10-20")).not.toMatch(/Octubre|De /)
  })

  it("no corre el día por la zona horaria", () => {
    expect(formatLongDate("2026-01-01")).toBe("Jueves 1 de enero")
    expect(formatLongDate("2026-12-31")).toBe("Jueves 31 de diciembre")
  })

  it("acepta un timestamp ISO y usa solo su fecha", () => {
    expect(formatLongDate("2026-10-12T23:30:00")).toBe("Lunes 12 de octubre")
  })

  it("devuelve vacío con una fecha inválida", () => {
    expect(formatLongDate("")).toBe("")
    expect(formatLongDate("2026-13-45")).toBe("")
  })
})

describe("formatLongDateInline", () => {
  it("deja el día de la semana en minúscula para usarlo dentro de una frase", () => {
    expect(formatLongDateInline("2026-10-12")).toBe("lunes 12 de octubre")
    expect(formatLongDateInline("2026-11-05")).toBe("jueves 5 de noviembre")
  })

  it("devuelve vacío con una fecha inválida", () => {
    expect(formatLongDateInline("")).toBe("")
  })
})

describe("formatShortDate", () => {
  it("usa dd/mm/aa con ceros a la izquierda", () => {
    expect(formatShortDate("2026-11-05")).toBe("05/11/26")
    expect(formatShortDate("2026-10-02")).toBe("02/10/26")
  })

  it("devuelve vacío con una fecha inválida", () => {
    expect(formatShortDate("")).toBe("")
    expect(formatShortDate("05/11/26")).toBe("")
  })
})

describe("formatShortDateTime", () => {
  it("agrega la hora local a la fecha corta", () => {
    expect(formatShortDateTime("2026-11-05T09:07:00")).toBe("05/11/26 09:07")
  })

  it("devuelve vacío con un timestamp inválido", () => {
    expect(formatShortDateTime("nunca")).toBe("")
  })
})
