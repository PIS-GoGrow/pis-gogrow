import { act, renderHook } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import useSessionStorage from "./use-session-storage"

describe("useSessionStorage", () => {
  beforeEach(() => {
    window.sessionStorage.clear()
    vi.restoreAllMocks()
  })

  it("devuelve el valor inicial cuando sessionStorage está vacío", () => {
    const { result } = renderHook(() =>
      useSessionStorage("cart", [{ id: 1, quantity: 2 }]),
    )

    expect(result.current[0]).toEqual([{ id: 1, quantity: 2 }])
  })

  it("lee el valor persistido de sessionStorage al montar", () => {
    window.sessionStorage.setItem(
      "cart",
      JSON.stringify([{ id: 42, quantity: 1 }]),
    )

    const { result } = renderHook(() => useSessionStorage("cart", []))

    expect(result.current[0]).toEqual([{ id: 42, quantity: 1 }])
  })

  it("actualiza el estado y sessionStorage cuando setValue recibe un valor directo", () => {
    const { result } = renderHook(() => useSessionStorage<string[]>("tags", []))

    act(() => {
      result.current[1](["veggie", "sin-sal"])
    })

    expect(result.current[0]).toEqual(["veggie", "sin-sal"])
    expect(window.sessionStorage.getItem("tags")).toBe(
      JSON.stringify(["veggie", "sin-sal"]),
    )
  })

  it("actualiza el estado usando un actualizador funcional (prev => next)", () => {
    const { result } = renderHook(() => useSessionStorage("counter", 10))

    act(() => {
      result.current[1]((prev) => prev + 5)
    })

    expect(result.current[0]).toBe(15)
    expect(window.sessionStorage.getItem("counter")).toBe("15")
  })

  it("sincroniza el estado entre múltiples instancias del hook que usan la misma clave", () => {
    const { result: hookA } = renderHook(() =>
      useSessionStorage<{ id: number; quantity: number }[]>("shared_cart", []),
    )
    const { result: hookB } = renderHook(() =>
      useSessionStorage<{ id: number; quantity: number }[]>("shared_cart", []),
    )

    act(() => {
      hookA.current[1]([{ id: 99, quantity: 3 }])
    })

    expect(hookA.current[0]).toEqual([{ id: 99, quantity: 3 }])
    expect(hookB.current[0]).toEqual([{ id: 99, quantity: 3 }])
  })

  it("elimina la clave de sessionStorage cuando setValue recibe undefined", () => {
    window.sessionStorage.setItem("cart", JSON.stringify([{ id: 1 }]))
    const { result } = renderHook(() =>
      useSessionStorage<{ id: number }[] | undefined>("cart", []),
    )

    act(() => {
      result.current[1](undefined)
    })

    expect(window.sessionStorage.getItem("cart")).toBeNull()
    expect(result.current[0]).toEqual([])
  })

  it("elimina la clave y restablece el valor fallback cuando se llama a remove()", () => {
    window.sessionStorage.setItem("cart", JSON.stringify([{ id: 10 }]))
    const { result } = renderHook(() => useSessionStorage("cart", []))

    expect(result.current[0]).toEqual([{ id: 10 }])

    act(() => {
      result.current[2]()
    })

    expect(window.sessionStorage.getItem("cart")).toBeNull()
    expect(result.current[0]).toEqual([])
  })

  it("hace fallback seguro al valor inicial si el JSON en sessionStorage está corrupto", () => {
    window.sessionStorage.setItem("cart", "{invalid_json_content...")

    const { result } = renderHook(() =>
      useSessionStorage("cart", [{ fallback: true }]),
    )

    expect(result.current[0]).toEqual([{ fallback: true }])
  })

  it("tolera errores cuando sessionStorage.getItem o setItem arrojan excepciones", () => {
    const getItemSpy = vi
      .spyOn(Storage.prototype, "getItem")
      .mockImplementation(() => {
        throw new Error("QuotaExceeded / SecurityError")
      })

    const { result } = renderHook(() => useSessionStorage("key", "default"))
    expect(result.current[0]).toBe("default")

    getItemSpy.mockRestore()

    const setItemSpy = vi
      .spyOn(Storage.prototype, "setItem")
      .mockImplementation(() => {
        throw new Error("QuotaExceeded")
      })

    expect(() => {
      act(() => {
        result.current[1]("new_val")
      })
    }).not.toThrow()

    setItemSpy.mockRestore()
  })
})
