import { act, renderHook } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import type { CartItem } from "@/pages/consumer/dashboard/consumer-types"
import type { SessionRole } from "@/types"

import {
  cleanupConsumerCartStorage,
  consumerCartStorageKey,
  useConsumerCart,
  useConsumerCartCleanup,
} from "./use-consumer-cart"

const page = vi.hoisted<{
  props: { auth: { session: { id: number; role: SessionRole } } }
}>(() => ({
  props: {
    auth: { session: { id: 10, role: "consumer" } },
  },
}))

vi.mock("@inertiajs/react", () => ({ usePage: () => page }))

const item: CartItem = {
  id: 1,
  date: "2026-10-30",
  remaining: 10,
  sold_out: false,
  orders_closed: false,
  menu: {
    id: 1,
    name: "Milanesa",
    description: null,
    price: 300,
    provider_id: 1,
    option_groups: [],
    provider_name: "Proveedor",
    home_delivery: false,
    rating_average: null,
    rating_count: 0,
    reviews: [],
  },
  cartId: "item-1",
  quantity: 1,
  notes: "",
  selections: {},
  benefits: [],
}

function useCartWithCleanup() {
  useConsumerCartCleanup()
  return useConsumerCart()
}

describe("useConsumerCart", () => {
  beforeEach(() => {
    window.sessionStorage.clear()
    page.props.auth.session = { id: 10, role: "consumer" }
  })

  it("construye la clave con el rol y el ID de la sesión autenticada", () => {
    expect(consumerCartStorageKey(page.props.auth.session)).toBe(
      "consumer-cart:consumer:10",
    )
  })

  it("persiste y sincroniza el carrito entre consumidores del hook en la misma sesión", () => {
    const { result: menu } = renderHook(() => useCartWithCleanup())
    const { result: cart } = renderHook(() => useCartWithCleanup())

    act(() => menu.current[1]([item]))

    expect(cart.current[0]).toEqual([item])
    expect(window.sessionStorage.getItem("consumer-cart:consumer:10")).toBe(
      JSON.stringify([item]),
    )
  })

  it("mantiene las selecciones al volver a montar dentro de la misma sesión", () => {
    const first = renderHook(() => useCartWithCleanup())
    act(() => first.result.current[1]([item]))
    first.unmount()

    const second = renderHook(() => useCartWithCleanup())

    expect(second.result.current[0]).toEqual([item])
  })

  it("aísla una nueva sesión del mismo empleado y elimina el carrito anterior", () => {
    const { result, rerender } = renderHook(() => useCartWithCleanup())
    act(() => result.current[1]([item]))

    page.props.auth.session = { id: 11, role: "consumer" }
    rerender()

    expect(result.current[0]).toEqual([])
    expect(
      window.sessionStorage.getItem("consumer-cart:consumer:10"),
    ).toBeNull()
  })

  it("aísla a otro empleado mediante su nueva sesión", () => {
    window.sessionStorage.setItem(
      "consumer-cart:consumer:20",
      JSON.stringify([item]),
    )
    page.props.auth.session = { id: 21, role: "consumer" }

    const { result } = renderHook(() => useCartWithCleanup())

    expect(result.current[0]).toEqual([])
    expect(
      window.sessionStorage.getItem("consumer-cart:consumer:20"),
    ).toBeNull()
  })

  it("no expone el carrito al cambiar de rol", () => {
    window.sessionStorage.setItem(
      "consumer-cart:consumer:10",
      JSON.stringify([item]),
    )
    page.props.auth.session = { id: 10, role: "provider" }

    const { result } = renderHook(() => useCartWithCleanup())

    expect(result.current[0]).toEqual([])
  })

  it("ignora y elimina la clave histórica sin tocar otros datos", () => {
    window.sessionStorage.setItem("cart", JSON.stringify([item]))
    window.sessionStorage.setItem("other-feature", "preserve-me")

    const { result } = renderHook(() => useCartWithCleanup())

    expect(result.current[0]).toEqual([])
    expect(window.sessionStorage.getItem("cart")).toBeNull()
    expect(window.sessionStorage.getItem("other-feature")).toBe("preserve-me")
  })

  it("limpia solamente carritos inactivos", () => {
    window.sessionStorage.setItem("cart", "legacy")
    window.sessionStorage.setItem("consumer-cart:consumer:9", "old")
    window.sessionStorage.setItem("consumer-cart:consumer:10", "active")
    window.sessionStorage.setItem("other-feature", "preserve-me")

    cleanupConsumerCartStorage("consumer-cart:consumer:10")

    expect(window.sessionStorage.getItem("cart")).toBeNull()
    expect(window.sessionStorage.getItem("consumer-cart:consumer:9")).toBeNull()
    expect(window.sessionStorage.getItem("consumer-cart:consumer:10")).toBe(
      "active",
    )
    expect(window.sessionStorage.getItem("other-feature")).toBe("preserve-me")
  })
})
