import { describe, expect, it } from "vitest"

import { formatMoney } from "./money"

describe("formatMoney", () => {
  it("muestra los enteros sin decimales y con punto de miles", () => {
    expect(formatMoney(300)).toBe("$300")
    expect(formatMoney(1250)).toBe("$1.250")
    expect(formatMoney(1050)).toBe("$1.050")
    expect(formatMoney(1234567)).toBe("$1.234.567")
  })

  it("agrega los centésimos solo cuando el importe los tiene", () => {
    expect(formatMoney(440.25)).toBe("$440,25")
    expect(formatMoney(2130.5)).toBe("$2.130,50")
    expect(formatMoney(300.0)).toBe("$300")
  })

  it("redondea los restos de punto flotante a centésimos", () => {
    expect(formatMoney(0.1 + 0.2)).toBe("$0,30")
    expect(formatMoney(449.999999)).toBe("$450")
  })

  it("pone el signo antes del símbolo en los importes negativos", () => {
    expect(formatMoney(-1250)).toBe("-$1.250")
    expect(formatMoney(-440.25)).toBe("-$440,25")
    expect(formatMoney(-0.001)).toBe("$0")
    expect(formatMoney(0)).toBe("$0")
    expect(formatMoney(-0)).toBe("$0")
  })

  it("acepta importes pasados como cadenas numéricas de Rails", () => {
    expect(formatMoney("300.25")).toBe("$300,25")
    expect(formatMoney("150.0")).toBe("$150")
    expect(formatMoney("1250")).toBe("$1.250")
    expect(formatMoney("-440.25")).toBe("-$440,25")
  })

  it("no depende del locale de la página", () => {
    expect(formatMoney(1250.5, "es")).toBe("$1.250,50")
    expect(formatMoney(1250.5, "es-UY")).toBe("$1.250,50")
  })
})
