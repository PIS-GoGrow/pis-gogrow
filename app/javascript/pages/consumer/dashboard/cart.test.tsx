import { act, cleanup, render, screen } from "@testing-library/react"
import type { ReactNode } from "react"
import type { ComponentProps } from "react"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

// AJUSTAR: ruta real del componente
import Cart from "./cart"

// ---------------------------------------------------------------------------
// Mocks compartidos (vi.hoisted para poder usarlos dentro de vi.mock)
// ---------------------------------------------------------------------------

const mocks = vi.hoisted(() => ({
  priceItems: vi.fn(),
  consumerCart: vi.fn(),
  orderError: vi.fn(),
  state: { initialCart: [] as unknown[] },
  form: {
    processing: false,
    errors: {},
    clearErrors: vi.fn(),
    transform: vi.fn(),
    post: vi.fn(),
    hasErrors: false,
  },
}))

// AJUSTAR: todas las rutas de vi.mock tienen que coincidir con los imports
// reales del componente (y si el import es nombrado en vez de default, también
// la forma del objeto devuelto).

vi.mock("@inertiajs/react", () => ({ useForm: () => mocks.form }))

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: ReactNode }) => <>{children}</>,
}))

vi.mock("@/lib/cart-pricing", () => ({
  priceItems: mocks.priceItems,
  cartPricedItem: (cart: { id: number; quantity: number }[]) =>
    cart.map((item) => ({ id: item.id, quantity: item.quantity })),
}))

vi.mock("@/hooks/use-session-storage", async () => {
  const { useState } = await import("react")
  const useSessionStorage = () => useState(mocks.state.initialCart)
  return { default: useSessionStorage, useSessionStorage }
})

vi.mock("@/pages/consumer/dashboard/consumer-cart", () => {
  const ConsumerCart = (props: unknown) => {
    mocks.consumerCart(props)
    return <div data-testid="consumer-cart" />
  }
  return { default: ConsumerCart, ConsumerCart }
})

vi.mock("@/pages/consumer/dashboard/order-error", () => {
  const OrderError = (props: unknown) => {
    mocks.orderError(props)
    return <div data-testid="order-error" />
  }
  return { default: OrderError, OrderError }
})

// ---------------------------------------------------------------------------
// Helpers y fixtures
// ---------------------------------------------------------------------------

interface Addr {
  address: string
}

interface CartProps {
  cart: { cartId: string }[]
  addresses: Addr[]
  address: string
  pricing: unknown
  loading: boolean
  confirm: () => void
  remove: (cartId: string) => void
  onAddAddress: (option: Addr, saved: boolean) => void
}

interface OrderErrorProps {
  error: string | undefined
  retry: () => void
}

const CALLE_1: Addr = { address: "Calle 1" }
const CALLE_2: Addr = { address: "Calle 2" }

const PRICING_OLD = { total: 100 }
const PRICING_NEW = { total: 250 }

function makeItem(
  cartId: string,
  overrides: Record<string, unknown> = {},
): Record<string, unknown> {
  return {
    cartId,
    id: 1,
    quantity: 1,
    notes: "",
    selections: {},
    ...overrides,
  }
}

function deferred<T>() {
  let resolve!: (value: T) => void
  let reject!: (reason?: unknown) => void
  const promise = new Promise<T>((res, rej) => {
    resolve = res
    reject = rej
  })
  return { promise, resolve, reject }
}

type CartComponentProps = ComponentProps<typeof Cart>

function element(addresses: Addr[]) {
  const props = {
    benefit: { monthly_limit: 1000, monthly_remaining: 500 },
    addresses,
  } as unknown as CartComponentProps

  return <Cart {...props} />
}

function actAsync(fn: () => void) {
  return act(() => {
    fn()
    return Promise.resolve()
  })
}

async function renderCart({
  addresses = [CALLE_1, CALLE_2],
  cart = [],
}: { addresses?: Addr[]; cart?: unknown[] } = {}) {
  mocks.state.initialCart = cart
  let utils!: ReturnType<typeof render>
  await actAsync(() => {
    utils = render(element(addresses))
  })
  return utils
}

const cartProps = () => mocks.consumerCart.mock.lastCall![0] as CartProps
const orderErrorProps = () =>
  mocks.orderError.mock.lastCall![0] as OrderErrorProps

/** Dispara confirm() y devuelve las opciones que se le pasaron a form.post */
function confirmAndGetPostOptions() {
  act(() => cartProps().confirm())
  return mocks.form.post.mock.calls[0][1] as {
    preserveState: boolean
    preserveScroll: boolean
    onSuccess: () => void
    onError: () => void
  }
}

beforeEach(() => {
  vi.resetAllMocks()
  mocks.state.initialCart = []
  mocks.form.processing = false
  mocks.form.errors = {}
  mocks.priceItems.mockResolvedValue(PRICING_OLD)
  mocks.form.hasErrors = false
  mocks.form.clearErrors.mockImplementation(() => {
    mocks.form.errors = {}
    mocks.form.hasErrors = false
  })
})

afterEach(cleanup)

// ---------------------------------------------------------------------------
// Cálculo de precio
// ---------------------------------------------------------------------------

describe("cálculo de precio", () => {
  it("con el carrito vacío no llama a priceItems, loading=false y pricing=null", async () => {
    await renderCart({ cart: [] })

    expect(mocks.priceItems).not.toHaveBeenCalled()
    expect(cartProps().loading).toBe(false)
    expect(cartProps().pricing).toBeNull()
  })

  it("ignora la respuesta vieja si el carrito cambia mientras hay una request en vuelo", async () => {
    const first = deferred<typeof PRICING_OLD>()
    const second = deferred<typeof PRICING_NEW>()
    mocks.priceItems
      .mockReturnValueOnce(first.promise)
      .mockReturnValueOnce(second.promise)

    await renderCart({ cart: [makeItem("a"), makeItem("b", { id: 2 })] })
    expect(mocks.priceItems).toHaveBeenCalledTimes(1)
    expect(cartProps().loading).toBe(true)

    // El carrito cambia con la primera request todavía pendiente
    act(() => cartProps().remove("b"))
    expect(mocks.priceItems).toHaveBeenCalledTimes(2)

    // Las promesas se resuelven en orden inverso: primero la nueva...
    await actAsync(() => {
      second.resolve(PRICING_NEW)
    })
    expect(cartProps().pricing).toEqual(PRICING_NEW)
    expect(cartProps().loading).toBe(false)

    // ...y después la vieja, que no debe pisar el resultado
    await actAsync(() => {
      first.resolve(PRICING_OLD)
    })
    expect(cartProps().pricing).toEqual(PRICING_NEW)
    expect(cartProps().loading).toBe(false)
  })
})

// ---------------------------------------------------------------------------
// Direcciones
// ---------------------------------------------------------------------------

describe("direcciones", () => {
  it("la dirección inicial es la primera de addresses", async () => {
    await renderCart({ addresses: [CALLE_1, CALLE_2] })

    expect(cartProps().address).toBe("Calle 1")
  })

  it("con addresses vacío, address es una cadena vacía", async () => {
    await renderCart({ addresses: [] })

    expect(cartProps().address).toBe("")
  })

  it("toma la primera dirección cuando addresses llega después del primer render", async () => {
    const utils = await renderCart({ addresses: [] })
    expect(cartProps().address).toBe("")

    await actAsync(() => {
      utils.rerender(element([CALLE_1]))
    })

    expect(cartProps().address).toBe("Calle 1")
  })

  it("onAddAddress con saved=false la agrega después de las guardadas y la selecciona", async () => {
    await renderCart({ addresses: [CALLE_1, CALLE_2] })

    act(() => cartProps().onAddAddress({ address: "Nueva" }, false))

    expect(cartProps().addresses.map((a) => a.address)).toEqual([
      "Calle 1",
      "Calle 2",
      "Nueva",
    ])
    expect(cartProps().address).toBe("Nueva")
  })

  it("no duplica una dirección sin guardar que ya existe en addresses", async () => {
    await renderCart({ addresses: [CALLE_1, CALLE_2] })

    act(() => cartProps().onAddAddress({ address: "Calle 2" }, false))

    expect(cartProps().addresses.map((a) => a.address)).toEqual([
      "Calle 1",
      "Calle 2",
    ])
    expect(cartProps().address).toBe("Calle 2")
  })

  it("agregar la misma dirección sin guardar dos veces deja una sola, primera entre las no guardadas", async () => {
    await renderCart({ addresses: [CALLE_1] })

    act(() => cartProps().onAddAddress({ address: "U1" }, false))
    act(() => cartProps().onAddAddress({ address: "U2" }, false))
    expect(cartProps().addresses.map((a) => a.address)).toEqual([
      "Calle 1",
      "U2",
      "U1",
    ])

    act(() => cartProps().onAddAddress({ address: "U1" }, false))

    expect(cartProps().addresses.map((a) => a.address)).toEqual([
      "Calle 1",
      "U1",
      "U2",
    ])
    expect(cartProps().address).toBe("U1")
  })

  it("onAddAddress con saved=true selecciona la dirección cuando llega en las props", async () => {
    const utils = await renderCart({ addresses: [CALLE_1] })

    act(() => cartProps().onAddAddress({ address: "Guardada" }, true))

    // Lo que hace Inertia al recargar después de guardar
    await actAsync(() => {
      utils.rerender(element([CALLE_1, { address: "Guardada" }]))
    })

    expect(cartProps().address).toBe("Guardada")
    expect(cartProps().addresses.map((a) => a.address)).toEqual([
      "Calle 1",
      "Guardada",
    ])
  })
})

// ---------------------------------------------------------------------------
// remove / retry / vistas
// ---------------------------------------------------------------------------

describe("remove", () => {
  it("saca solo el item con ese cartId y llama a clearErrors", async () => {
    await renderCart({
      cart: [makeItem("a"), makeItem("b", { id: 2 }), makeItem("c", { id: 3 })],
    })

    act(() => cartProps().remove("b"))

    expect(cartProps().cart.map((i) => i.cartId)).toEqual(["a", "c"])
    expect(mocks.form.clearErrors).toHaveBeenCalledTimes(1)
  })
})

describe("vista de error", () => {
  async function goToErrorView(serverError: unknown = "Sin saldo") {
    const utils = await renderCart({ cart: [makeItem("a")] })
    mocks.form.errors = { order_error: serverError }
    mocks.form.hasErrors = true
    await actAsync(() => {
      utils.rerender(element([CALLE_1, CALLE_2]))
    })
    return utils
  }

  it("retry limpia los errores y vuelve a la vista de carrito", async () => {
    const utils = await goToErrorView()
    expect(screen.queryByTestId("order-error")).not.toBeNull()
    expect(screen.queryByTestId("consumer-cart")).toBeNull()

    act(() => orderErrorProps().retry())
    await actAsync(() => {
      utils.rerender(element([CALLE_1, CALLE_2]))
    })

    expect(mocks.form.clearErrors).toHaveBeenCalledTimes(1)
    expect(screen.queryByTestId("order-error")).toBeNull()
    expect(screen.queryByTestId("consumer-cart")).not.toBeNull()
  })

  it.each([
    ["un string", "Sin saldo", "Sin saldo"],
    ["un array", ["Primero", "Segundo"], "Primero"],
  ])(
    "OrderError recibe el error correcto cuando order_error es %s",
    async (_label, serverError, expected) => {
      await goToErrorView(serverError)

      expect(orderErrorProps().error).toBe(expected)
    },
  )
})

// ---------------------------------------------------------------------------
// confirm
// ---------------------------------------------------------------------------

describe("confirm", () => {
  it("no hace post con el carrito vacío", async () => {
    await renderCart({ cart: [] })

    act(() => cartProps().confirm())

    expect(mocks.form.post).not.toHaveBeenCalled()
  })

  it("no hace post si el form está procesando", async () => {
    mocks.form.processing = true
    await renderCart({ cart: [makeItem("a")] })

    act(() => cartProps().confirm())

    expect(mocks.form.post).not.toHaveBeenCalled()
  })

  it("no hace post si no hay dirección", async () => {
    await renderCart({ addresses: [], cart: [makeItem("a")] })

    act(() => cartProps().confirm())

    expect(mocks.form.post).not.toHaveBeenCalled()
  })

  it("caso feliz: hace post a la URL correcta con las opciones y el payload esperados", async () => {
    await renderCart({
      cart: [
        makeItem("c1", {
          id: 7,
          quantity: 2,
          notes: "sin sal",
          selections: { "3": ["a", "b"], "5": ["x"] },
        }),
      ],
    })

    act(() => cartProps().confirm())

    expect(mocks.form.post).toHaveBeenCalledTimes(1)
    expect(mocks.form.post).toHaveBeenCalledWith(
      "/orders",
      expect.objectContaining({
        preserveState: true,
        preserveScroll: false,
      }),
    )

    // El payload sale del transform, no de los datos del useForm
    expect(mocks.form.transform).toHaveBeenCalledTimes(1)
    const transform = mocks.form.transform.mock.calls[0][0] as (
      data: unknown,
    ) => unknown
    expect(transform({})).toEqual({
      order: {
        address: "Calle 1",
        items: [
          {
            schedule_id: 7,
            quantity: 2,
            notes: "sin sal",
            options: [
              { group_id: 3, values: ["a", "b"] },
              { group_id: 5, values: ["x"] },
            ],
          },
        ],
      },
    })
  })

  it("onSuccess vacía el carrito", async () => {
    await renderCart({ cart: [makeItem("a"), makeItem("b", { id: 2 })] })
    const options = confirmAndGetPostOptions()

    act(() => options.onSuccess())

    expect(cartProps().cart).toEqual([])
  })

  it("muestra OrderError cuando el form tiene errores", async () => {
    const utils = await renderCart({ cart: [makeItem("a")] })
    expect(screen.queryByTestId("consumer-cart")).not.toBeNull()
    expect(screen.queryByTestId("order-error")).toBeNull()

    mocks.form.errors = { order_error: "Sin saldo" }
    mocks.form.hasErrors = true
    await actAsync(() => {
      utils.rerender(element([CALLE_1, CALLE_2]))
    })

    expect(screen.queryByTestId("order-error")).not.toBeNull()
    expect(screen.queryByTestId("consumer-cart")).toBeNull()
  })
})
