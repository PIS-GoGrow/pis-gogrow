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

  // Figma: una sola línea "Beneficio GoGrow" por plato, con el porcentaje
  // combinado del base y los especiales.
  it("shows the combined benefit in a single line per dish", () => {
    renderCart(
      { cart: [{ ...cartItem("Tu Viandita", true), quantity: 2 }] },
      { specials: [premio] },
    )

    expect(
      screen.getByText("Beneficio GoGrow (80%)").nextSibling,
    ).toHaveTextContent("- $448")
    expect(screen.queryByText("Premio (30%)")).not.toBeInTheDocument()
    expect(screen.getAllByText(/^Beneficio GoGrow/)).toHaveLength(1)
    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$112",
    )
  })

  it("shows one line per percentage when the meals of a dish differ", () => {
    renderCart(
      { cart: [{ ...cartItem("Tu Viandita", true), quantity: 3 }] },
      { monthly_remaining: 1, specials: [premio] },
    )

    // 3 x 280: la primera con 80%, la segunda solo con el premio y la tercera
    // a precio completo. 56 + 196 + 280 = 532.
    expect(
      screen.getByText("Beneficio GoGrow (80%)").nextSibling,
    ).toHaveTextContent("- $224")
    expect(
      screen.getByText("Beneficio GoGrow (30%)").nextSibling,
    ).toHaveTextContent("- $84")
    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$532",
    )
  })

  it("leaves the base alone when the special has no uses left", () => {
    renderCart({}, { specials: [{ ...premio, remaining: 0 }] })

    expect(screen.getByText("Beneficio GoGrow (50%)")).toBeInTheDocument()
    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$140",
    )
  })
})
