import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import type { ConsumerDashboardIndex } from "@/types"

import { ConsumerCart } from "./consumer-cart"
import type { CartItem, DeliveryAddressOption } from "./consumer-types"
import { cartPricedItem, priceItems } from "./pricing"

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
    <a href={href} {...props}>{children}</a>
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
