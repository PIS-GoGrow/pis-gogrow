import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import { ConsumerCart } from "./consumer-cart"
import type { CartItem, DeliveryAddressOption } from "./consumer-types"
import { type Benefit, cartPricedItem, priceItems } from "./pricing"

// El formulario de "Agregar una dirección" habla con el servidor; acá solo
// importa qué direcciones ofrece el carrito y cuándo.
vi.mock("@inertiajs/react", () => ({
  useForm: <T extends object>(initial: T) => ({
    data: initial,
    setData: vi.fn(),
    post: vi.fn(),
    processing: false,
    errors: {},
    clearErrors: vi.fn(),
    reset: vi.fn(),
    transform: vi.fn(),
  }),
}))

// IBP-014 — "Como EMPLEADO, quiero ingresar una dirección de entrega
// personalizada cuando el proveedor lo permita para recibir el pedido fuera de
// la oficina."

const addresses: DeliveryAddressOption[] = [
  { id: "office", label: "Oficina", address: "Av. 18 de Julio 1006" },
  { id: "address-2", label: "Casa", address: "Ellauri 1234" },
  { id: "address-3", label: "Flora Café", address: "Canelones 892" },
  { id: "address-4", label: "La Bicicleta Café", address: "Bv. España 2643" },
]

const cartItem = (
  providerName: string,
  homeDelivery: boolean,
  id = 1,
): CartItem => ({
  id,
  cartId: `${id}-`,
  date: "2026-09-14",
  remaining: 5,
  sold_out: false,
  orders_closed: false,
  quantity: 1,
  notes: "",
  selections: {},
  menu: {
    id: id * 10,
    name: `Plato ${id}`,
    description: null,
    price: 280,
    option_groups: [],
    provider_name: providerName,
    home_delivery: homeDelivery,
    reviews: [],
  },
})

const benefit: Benefit = {
  limit: 5,
  used: 0,
  percentage: 50,
  monthly_limit: 20,
  monthly_used: 0,
  monthly_remaining: 20,
  specials: [],
}

function renderCart(
  props: Partial<Parameters<typeof ConsumerCart>[0]> = {},
  benefitProps: Partial<Benefit> = {},
) {
  const cart = props.cart ?? [cartItem("Tu Viandita", true)]
  const defaults = {
    monthlyLimit: 20,
    monthlyRemaining: 20,
    pricing: priceItems(cart.map(cartPricedItem), {
      ...benefit,
      ...benefitProps,
    }),
    cart,
    addresses,
    address: "Av. 18 de Julio 1006",
    setAddress: vi.fn(),
    onAddAddress: vi.fn(),
    processing: false,
    back: vi.fn(),
    confirm: vi.fn(),
    remove: vi.fn(),
    setQuantity: vi.fn(),
  }
  return render(<ConsumerCart {...defaults} {...props} />)
}

describe("ConsumerCart delivery address", () => {
  it("shows the office and the last custom address used", () => {
    renderCart()

    const options = screen.getAllByRole("radio")
    expect(options).toHaveLength(2)
    expect(screen.getByRole("radio", { name: /Oficina/ })).toBeChecked()
    expect(screen.getByRole("radio", { name: /Casa/ })).not.toBeChecked()
    expect(screen.queryByText("Flora Café")).not.toBeInTheDocument()
  })

  it("shows the selected custom address next to the office", () => {
    renderCart({ address: "Canelones 892" })

    expect(screen.getByRole("radio", { name: /Flora Café/ })).toBeChecked()
    expect(screen.queryByText("Casa")).not.toBeInTheDocument()
  })

  it("lets the employee pick any of their addresses", async () => {
    const user = userEvent.setup()
    const setAddress = vi.fn()
    renderCart({ setAddress })

    await user.click(
      screen.getByRole("button", { name: "Ver mis direcciones" }),
    )
    const sheet = screen.getByRole("dialog", { name: "Mis direcciones" })
    expect(within(sheet).getAllByRole("radio")).toHaveLength(4)

    await user.click(within(sheet).getByRole("radio", { name: /La Bicicleta/ }))
    await user.click(within(sheet).getByRole("button", { name: "Seleccionar" }))

    expect(setAddress).toHaveBeenCalledWith("Bv. España 2643")
  })

  it("opens the form to add a new address", async () => {
    const user = userEvent.setup()
    renderCart()

    await user.click(screen.getByRole("button", { name: "Agregar" }))
    const sheet = screen.getByRole("dialog", {
      name: "Agregar una dirección",
    })

    expect(within(sheet).getByLabelText("Nombre")).toHaveAttribute(
      "placeholder",
      "Ej: Oficina, Casa, etc.",
    )
    expect(within(sheet).getByLabelText("Dirección")).toBeInTheDocument()
    expect(
      within(sheet).getByLabelText("Piso / Apartamento (opcional)"),
    ).toBeInTheDocument()
    expect(
      within(sheet).getByRole("checkbox", {
        name: "Guardar esta dirección para futuros pedidos",
      }),
    ).not.toBeChecked()
  })

  // Criterio 1: la dirección personalizada solo se habilita si el proveedor
  // entrega a domicilio.
  it("keeps the order at the office when no provider delivers home", () => {
    renderCart({
      cart: [cartItem("Endulzate by Noe", false)],
      address: "Ellauri 1234",
    })

    expect(screen.getByRole("radio", { name: /Oficina/ })).toBeChecked()
    expect(screen.getByRole("radio", { name: /Casa/ })).toBeDisabled()
    expect(screen.getByRole("button", { name: "Agregar" })).toBeDisabled()
    expect(
      screen.getByRole("button", { name: "Ver mis direcciones" }),
    ).toBeDisabled()
  })

  it("warns which provider only delivers to the office in a mixed cart", () => {
    renderCart({
      cart: [
        cartItem("Endulzate by Noe", false, 1),
        cartItem("Tu Viandita", true, 2),
      ],
      address: "Ellauri 1234",
    })

    expect(
      screen.getByText(
        "Endulzate by Noe entrega en la Oficina. Sus viandas irán allí y las demás a la dirección seleccionada.",
      ),
    ).toBeInTheDocument()
  })

  it("lists every office-only provider in a single warning", () => {
    renderCart({
      cart: [
        cartItem("Endulzate by Noe", false, 1),
        cartItem("Dulce Sur", false, 2),
        cartItem("La Olla", false, 3),
        cartItem("Tu Viandita", true, 4),
      ],
      address: "Ellauri 1234",
    })

    expect(
      screen.getByText(
        "Endulzate by Noe, Dulce Sur y La Olla entregan en la Oficina. Sus viandas irán allí y las demás a la dirección seleccionada.",
      ),
    ).toBeInTheDocument()
  })
})

// IBP-037: el subsidio especial se suma al base, y cada línea del carrito
// muestra qué beneficio le descuenta cuánto.
describe("ConsumerCart benefits", () => {
  const premio = {
    id: 7,
    name: "Premio",
    percentage: 30,
    remaining: 2,
    due_date: null,
  }

  it("shows each benefit in a separate line per dish", () => {
    renderCart(
      { cart: [{ ...cartItem("Tu Viandita", true), quantity: 2 }] },
      { specials: [premio] },
    )

    expect(
      screen.getByText("Subsidio Base (50%)").nextSibling,
    ).toHaveTextContent("- $280")
    expect(screen.getByText("Premio (30%)").nextSibling).toHaveTextContent(
      "- $168",
    )
    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$112",
    )
  })

  it("shows each active benefit when the meals of a dish differ", () => {
    renderCart(
      { cart: [{ ...cartItem("Tu Viandita", true), quantity: 3 }] },
      { monthly_remaining: 1, specials: [premio] },
    )

    // 3 x 280: la primera con 50% base + 30% premio, la segunda solo con 30% premio y la tercera
    // a precio completo. 56 + 196 + 280 = 532.
    expect(
      screen.getByText("Subsidio Base (50%)").nextSibling,
    ).toHaveTextContent("- $140")
    expect(screen.getByText("Premio (30%)").nextSibling).toHaveTextContent(
      "- $168",
    )
    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$532",
    )
  })

  it("leaves the base alone when the special has no uses left", () => {
    renderCart({}, { specials: [{ ...premio, remaining: 0 }] })

    expect(screen.getByText("Subsidio Base (50%)")).toBeInTheDocument()
    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$140",
    )
  })
})

describe("ConsumerCart quantity", () => {
  const twoDishes = (quantity: number): CartItem[] => [
    { ...cartItem("Tu Viandita", true, 1), quantity },
    cartItem("Tu Viandita", true, 2),
  ]

  it("changes the quantity of the dish whose counter was used", async () => {
    const setQuantity = vi.fn()
    renderCart({ cart: twoDishes(3), setQuantity })

    await userEvent.click(
      screen.getByRole("button", { name: "Agregar una unidad de Plato 1" }),
    )
    await userEvent.click(
      screen.getByRole("button", { name: "Quitar una unidad de Plato 1" }),
    )

    expect(setQuantity).toHaveBeenNthCalledWith(1, "1-", 4)
    expect(setQuantity).toHaveBeenNthCalledWith(2, "1-", 2)
  })

  it("turns the minus into a trash that removes the dish at quantity 1", async () => {
    const remove = vi.fn()
    const setQuantity = vi.fn()
    renderCart({ cart: twoDishes(2), remove, setQuantity })

    expect(
      screen.queryByRole("button", { name: "Quitar Plato 1" }),
    ).not.toBeInTheDocument()
    // El plato 2 tiene cantidad 1: ya muestra el tacho.
    await userEvent.click(
      screen.getByRole("button", { name: "Quitar Plato 2" }),
    )

    expect(remove).toHaveBeenCalledWith("2-")
    expect(setQuantity).not.toHaveBeenCalled()
  })

  it("does not go above the remaining stock", () => {
    renderCart({ cart: [{ ...cartItem("Tu Viandita", true), quantity: 5 }] })

    expect(
      screen.getByRole("button", { name: "Agregar una unidad de Plato 1" }),
    ).toBeDisabled()
  })

  it("disables the counters while the order is processing", () => {
    renderCart({ cart: twoDishes(2), processing: true })

    expect(
      screen.getByRole("button", { name: "Quitar una unidad de Plato 1" }),
    ).toBeDisabled()
    expect(
      screen.getByRole("button", { name: "Quitar Plato 2" }),
    ).toBeDisabled()
  })
})
