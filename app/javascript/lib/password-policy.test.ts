import { describe, expect, it } from "vitest"

import { isStrongPassword, passwordRules } from "./password-policy"

describe("passwordRules", () => {
  const passing = (password: string) =>
    passwordRules.filter((rule) => rule.test(password)).map((rule) => rule.key)

  it("marks each requirement on its own", () => {
    expect(passing("")).toEqual([])
    expect(passing("abcdefghijklmnop")).toEqual(["min_length"])
    expect(passing("A")).toEqual(["uppercase"])
    expect(passing("1")).toEqual(["number"])
    expect(passing("!")).toEqual(["special"])
  })

  it("does not take a letter with an accent or an ñ as a special character", () => {
    expect(passing("áéíñ")).toEqual([])
  })
})

describe("isStrongPassword", () => {
  it("accepts 16 characters with an uppercase letter, a number and a special character", () => {
    expect(isStrongPassword("Nueva-Clave-2026-ok!")).toBe(true)
  })

  it("rejects a password that misses any requirement", () => {
    expect(isStrongPassword("Aa1!aaaaaaaaaaa")).toBe(false)
    expect(isStrongPassword("nueva-clave-2026-ok!")).toBe(false)
    expect(isStrongPassword("Nueva-Clave-Segura-ok!")).toBe(false)
    expect(isStrongPassword("NuevaClave2026okayy")).toBe(false)
  })
})
