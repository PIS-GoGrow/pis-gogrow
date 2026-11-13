import { renderHook } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

import { useFormatters } from "./use-formatters"

vi.mock("@inertiajs/react", () => ({
  usePage: () => ({ props: { locale: "es" } }),
}))

describe("useFormatters", () => {
  describe("formatMoney", () => {
    const { formatMoney } = renderHook(() => useFormatters()).result.current

    it("pega el símbolo y agrupa los miles aunque sean cuatro cifras", () => {
      expect(formatMoney(2400)).toBe("$2.400")
      expect(formatMoney(12400)).toBe("$12.400")
    })

    it("no agrega decimales a un monto entero", () => {
      expect(formatMoney(0)).toBe("$0")
      expect(formatMoney(1250)).toBe("$1.250")
    })

    it("conserva los centavos cuando los hay", () => {
      expect(formatMoney(300.5)).toBe("$300,50")
      expect(formatMoney(440.25)).toBe("$440,25")
    })
  })

  describe("fechas", () => {
    const { formatLongDate, formatLongDateInline, formatShortDate } =
      renderHook(() => useFormatters()).result.current

    it("escribe la fecha larga con el día de la semana", () => {
      expect(formatLongDate("2026-10-07")).toBe("Miércoles 7 de octubre")
    })

    it("escribe la fecha larga en minúscula para usarla dentro de una frase", () => {
      expect(formatLongDateInline("2026-10-07")).toBe("miércoles 7 de octubre")
    })

    it("escribe la fecha corta como dd/mm/aa", () => {
      expect(formatShortDate("2026-10-07")).toBe("07/10/26")
    })
  })
})
