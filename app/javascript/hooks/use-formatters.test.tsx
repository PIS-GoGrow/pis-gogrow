import { renderHook } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

import { useFormatters } from "./use-formatters"

vi.mock("@inertiajs/react", () => ({
  usePage: () => ({ props: { locale: "es" } }),
}))

describe("useFormatters", () => {
  describe("formatMoneyShort", () => {
    const { formatMoneyShort } = renderHook(() => useFormatters()).result
      .current

    it("pega el símbolo y agrupa los miles aunque sean cuatro cifras", () => {
      expect(formatMoneyShort(2400)).toBe("$2.400")
      expect(formatMoneyShort(12400)).toBe("$12.400")
    })

    it("no agrega decimales a un monto entero", () => {
      expect(formatMoneyShort(0)).toBe("$0")
    })

    it("conserva los centavos cuando los hay", () => {
      expect(formatMoneyShort(300.5)).toBe("$300,50")
    })
  })
})
