import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import type { ConsumerDashboardIndex } from "@/types"

import { ConsumerCart } from "./consumer-cart"
import type { CartItem, DeliveryAddressOption } from "./consumer-types"
import { type Pricing, cartPricedItem, priceItems } from "./pricing"

type Benefit = ConsumerDashboardIndex["benefit"]

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
  Link: ({ href, children, ...props }: React.ComponentProps<"a">) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
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
    provider_id: id,
    option_groups: [],
    provider_name: providerName,
    home_delivery: homeDelivery,
    reviews: [],
  },
})

const benefit: Benefit = {
  percentage: 50,
  monthly_limit: 20,
  monthly_used: 0,
  monthly_remaining: 20,
  specials: [],
}

async function renderCart(
  props: Partial<Parameters<typeof ConsumerCart>[0]> = {},
  benefitProps: Partial<Benefit> = {},
) {
  const cart = props.cart ?? [cartItem("Tu Viandita", true)]

  vi.spyOn(globalThis, "fetch").mockResolvedValue(
    new Response(JSON.stringify({ ...benefit, ...benefitProps }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    }),
  )

  const result = await priceItems(cartPricedItem(cart))

  const defaults = {
    monthlyLimit: 20,
    monthlyRemaining: 20,
    pricing: result,
    cart,
    addresses,
    loading: false,
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
  it("shows the office and the last custom address used", async () => {
    await renderCart()

    const options = screen.getAllByRole("radio")
    expect(options).toHaveLength(2)
    expect(screen.getByRole("radio", { name: /Oficina/ })).toBeChecked()
    expect(screen.getByRole("radio", { name: /Casa/ })).not.toBeChecked()
    expect(screen.queryByText("Flora Café")).not.toBeInTheDocument()
  })

  it("shows the selected custom address next to the office", async () => {
    await renderCart({ address: "Canelones 892" })

    expect(screen.getByRole("radio", { name: /Flora Café/ })).toBeChecked()
    expect(screen.queryByText("Casa")).not.toBeInTheDocument()
  })

  it("lets the employee pick any of their addresses", async () => {
    const user = userEvent.setup()
    const setAddress = vi.fn()
    await renderCart({ setAddress })

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
    await renderCart()

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
  it("keeps the order at the office when no provider delivers home", async () => {
    await renderCart({
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

  it("warns which provider only delivers to the office in a mixed cart", async () => {
    await renderCart({
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

  it("lists every office-only provider in a single warning", async () => {
    await renderCart({
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

describe("ConsumerCart delivery date", () => {
  it("shows a single delivery date under the title instead of on every dish", async () => {
    await renderCart({
      cart: [
        cartItem("Tu Viandita", true, 1),
        cartItem("Tu Viandita", true, 2),
      ],
    })

    const date = screen.getByText("Entrega: Lunes 14 de setiembre")

    expect(screen.getAllByText(/^Entrega:/)).toHaveLength(1)
    expect(screen.getByRole("heading", { name: "Tu carrito" })).toHaveProperty(
      "nextElementSibling",
      date,
    )
  })

  it("keeps a date on each dish when the cart spans several days", async () => {
    await renderCart({
      cart: [
        cartItem("Tu Viandita", true, 1),
        { ...cartItem("Tu Viandita", true, 2), date: "2026-09-15" },
      ],
    })

    expect(
      screen.getByText("Entrega: Lunes 14 de setiembre"),
    ).toBeInTheDocument()
    expect(
      screen.getByText("Entrega: Martes 15 de setiembre"),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("heading", { name: "Tu carrito" }).nextElementSibling,
    ).toHaveProperty("tagName", "SECTION")
  })
})

// IBP-006 CA10 — "Si no corresponde subsidio, el sistema muestra valor cero y
// el motivo."
describe("ConsumerCart without subsidy", () => {
  const fullPrice = (quantity: number, subsidized = 0): Pricing => ({
    subtotal: 301 * quantity,
    discount: 0,
    total: 301 * quantity,
    lines: {
      "1": {
        subtotal: 301 * quantity,
        discount: 0,
        total: 301 * quantity,
        tiers: [],
      },
    },
    subsidizedQuantity: subsidized,
    fullPriceQuantity: quantity - subsidized,
  })

  it("shows the GoGrow subsidy at zero for a dish without benefit", async () => {
    await renderCart({
      monthlyLimit: 0,
      monthlyRemaining: 0,
      pricing: fullPrice(1),
    })

    expect(screen.getByText("Subsidio GoGrow").nextSibling).toHaveTextContent(
      "$0",
    )
  })

  it("says the employee has no benefit instead of claiming they used it up", async () => {
    await renderCart({
      monthlyLimit: 0,
      monthlyRemaining: 0,
      pricing: fullPrice(1),
    })

    expect(
      screen.getByText(
        "No tenés un beneficio asignado. La vianda de este pedido se cobra a precio completo.",
      ),
    ).toBeInTheDocument()
    expect(screen.queryByText(/Ya utilizaste/)).not.toBeInTheDocument()
  })

  it("says the monthly quota is used up when it had one", async () => {
    await renderCart({
      monthlyLimit: 20,
      monthlyRemaining: 0,
      pricing: fullPrice(2),
    })

    expect(
      screen.getByText(
        "Ya utilizaste las 20 viandas subsidiadas de este mes. Las 2 viandas de este pedido se cobran a precio completo.",
      ),
    ).toBeInTheDocument()
  })

  it("splits the order when only part of it is subsidized", async () => {
    await renderCart({
      monthlyLimit: 20,
      monthlyRemaining: 1,
      pricing: fullPrice(3, 1),
    })

    expect(
      screen.getByText(
        "Te queda 1 vianda subsidiada este mes. De este pedido, 1 con beneficio y 2 a precio completo.",
      ),
    ).toBeInTheDocument()
  })
})

describe("ConsumerCart quantity", () => {
  const twoDishes = (quantity: number): CartItem[] => [
    { ...cartItem("Tu Viandita", true, 1), quantity },
    cartItem("Tu Viandita", true, 2),
  ]

  it("changes the quantity of the dish whose counter was used", async () => {
    const setQuantity = vi.fn()
    await renderCart({ cart: twoDishes(3), setQuantity })

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
    await renderCart({ cart: twoDishes(2), remove, setQuantity })

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

  it("does not go above the remaining stock", async () => {
    await renderCart({
      cart: [{ ...cartItem("Tu Viandita", true), quantity: 5 }],
    })

    expect(
      screen.getByRole("button", { name: "Agregar una unidad de Plato 1" }),
    ).toBeDisabled()
  })

  it("disables the counters while the order is processing", async () => {
    await renderCart({ cart: twoDishes(2), processing: true })

    expect(
      screen.getByRole("button", { name: "Quitar una unidad de Plato 1" }),
    ).toBeDisabled()
    expect(
      screen.getByRole("button", { name: "Quitar Plato 2" }),
    ).toBeDisabled()
  })
})
