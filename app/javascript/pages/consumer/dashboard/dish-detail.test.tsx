import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it, vi } from "vitest"

import type { ConsumerDashboardIndex } from "@/types"

import type { CartItem, Schedule } from "./consumer-types"
import { DishDetail } from "./dish-detail"
import type { Pricing } from "./pricing"

type Benefit = ConsumerDashboardIndex["benefit"]

// Historia: "Como EMPLEADO, quiero consultar la información relevante de cada
// plato, para tomar una decisión informada." Esta es la pantalla donde el
// empleado ve esa información antes de decidir.
//
// TODO(integración): falta corregir el bloque de opiniones antes de poder
// testear qué se muestra cuando un plato no tiene reseñas. Hoy la pantalla
// fabrica una reseña de ejemplo, un puntaje 4.8, un autor ("Pedro"/"Lucía") y
// una fecha fija, ninguno de los cuales sale de los datos — y Review ni
// siquiera tiene columna de autor. Está registrado como defecto
// (DEFECT-detalle-plato-reseñas-inventadas): no se fija acá el comportamiento
// actual como si fuera el correcto. Historia, criterio 3: "si un dato opcional
// no fue informado, la interfaz no muestra información engañosa ni valores
// inventados".

const schedule = (overrides: Partial<Schedule["menu"]> = {}): Schedule => ({
  id: 1,
  date: "2026-09-16",
  remaining: 5,
  sold_out: false,
  orders_closed: false,
  menu: {
    id: 10,
    name: "Sorrentinos artesanales",
    description: "Pasta rellena a elección",
    price: 320,
    option_groups: [],
    provider_name: "Endulzate by Noe",
    home_delivery: true,
    reviews: [],
    ...overrides,
  },
})

const benefit: Benefit = {
  percentage: 50,
  monthly_limit: 20,
  monthly_used: 0,
  monthly_remaining: 20,
  specials: [],
}

function renderDetail(props: Partial<Parameters<typeof DishDetail>[0]> = {}) {
  const defaults = {
    item: schedule(),
    quantity: 1,
    setQuantity: vi.fn(),
    notes: "",
    setNotes: vi.fn(),
    selections: {},
    setSelections: vi.fn(),
    cart: [] as CartItem[],
    back: vi.fn(),
    add: vi.fn(),
    benefit: benefit,
  }
  return render(<DishDetail {...defaults} {...props} />)
}

const mocks = vi.hoisted(() => ({ priceItems: vi.fn() }))

vi.mock("@/pages/consumer/dashboard/pricing", () => ({
  priceItems: mocks.priceItems,
  cartPricedItem: (cart: { id: number; quantity: number }[]) =>
    cart.map((item) => ({ schedule_id: item.id, quantity: item.quantity })),
}))

beforeEach(() => {
  mocks.priceItems.mockResolvedValue(null) // o un fixture de Pricing
})

describe("DishDetail", () => {
  // Criterio 1
  it("shows the name, the provider, the description and the price of the dish", () => {
    // Cantidad 2 para que el precio unitario del plato no se confunda con el
    // total del resumen, que con cantidad 1 da el mismo número.
    renderDetail({ quantity: 2 })

    expect(
      screen.getByRole("heading", { name: "Sorrentinos artesanales" }),
    ).toBeInTheDocument()
    expect(screen.getByText("Endulzate by Noe")).toBeInTheDocument()
    expect(screen.getByText("Pasta rellena a elección")).toBeInTheDocument()
    expect(screen.getByText("$320")).toBeInTheDocument()
  })

  // Criterio 3: sin descripción no se inventa texto, y sobre todo no se filtra
  // el "null" del prop a la pantalla, que es la forma más común de que esto
  // salga mal.
  it("does not invent a description for a dish that has none", () => {
    const { container } = renderDetail({
      item: schedule({ description: null }),
    })

    expect(
      screen.queryByText("Pasta rellena a elección"),
    ).not.toBeInTheDocument()
    expect(container.textContent).not.toMatch(/null|undefined|NaN/)
    expect(
      screen.getByRole("heading", { name: "Sorrentinos artesanales" }),
    ).toBeInTheDocument()
  })

  // Criterio 1, disponibilidad: el cupo restante es el techo de lo que se puede
  // pedir, y la pantalla lo respeta.
  it("does not let the quantity go past the remaining quota", () => {
    renderDetail({ item: { ...schedule(), remaining: 2 }, quantity: 2 })

    expect(screen.getByRole("button", { name: "Agregar uno" })).toBeDisabled()
  })

  it("marks the dish as added when it is already in the cart", () => {
    const added: CartItem = {
      ...schedule(),
      cartId: "1-",
      quantity: 1,
      notes: "",
      selections: {},
      benefits: [],
    }

    renderDetail({ cart: [added] })

    expect(screen.getByText("Agregado")).toBeInTheDocument()
  })

  it("does not mark a dish that is not in the cart", () => {
    renderDetail()

    expect(screen.queryByText("Agregado")).not.toBeInTheDocument()
  })

  it("shows the real reviews of the dish", () => {
    renderDetail({
      item: schedule({
        reviews: [
          {
            id: 7,
            description: "La salsa filetto es la mejor",
            rating: 5,
            created_at: "2026-09-15",
          },
        ],
      }),
    })

    expect(screen.getByText("La salsa filetto es la mejor")).toBeInTheDocument()
  })

  const groups = [
    {
      id: 1,
      name: "relleno",
      options: ["Ricota y nuez", "Jamón y queso"],
      limit: 1,
      required: true,
    },
    {
      id: 2,
      name: "salsa",
      options: ["Filetto", "Puerro", "Rosa"],
      limit: 2,
      required: false,
    },
  ]

  // IBP-022, criterio 2: no se puede pedir sin resolver los grupos obligatorios.
  it("requires picking an option only from the required groups", async () => {
    const user = userEvent.setup()
    const add = vi.fn()
    const { rerender } = renderDetail({
      item: schedule({ option_groups: groups }),
      selections: { 2: ["Filetto"] },
      add,
    })

    expect(screen.getByRole("button", { name: "Agregar" })).toBeDisabled()

    rerender(
      <DishDetail
        item={schedule({ option_groups: groups })}
        quantity={1}
        setQuantity={vi.fn()}
        notes=""
        setNotes={vi.fn()}
        selections={{ 1: ["Ricota y nuez"] }}
        setSelections={vi.fn()}
        cart={[]}
        back={vi.fn()}
        add={add}
        benefit={benefit}
      />,
    )

    const button = screen.getByRole("button", { name: "Agregar" })
    expect(button).toBeEnabled()
    await user.click(button)
    expect(add).toHaveBeenCalledOnce()
  })

  it("tells which groups are required and which are optional", () => {
    renderDetail({ item: schedule({ option_groups: groups }) })

    expect(screen.getByText("Obligatorio")).toBeInTheDocument()
    expect(screen.getByText("Opcional")).toBeInTheDocument()
  })

  it("unselects the chosen option of a single-choice group", async () => {
    const user = userEvent.setup()
    const setSelections = vi.fn()
    renderDetail({
      item: schedule({ option_groups: groups }),
      selections: { 1: ["Ricota y nuez"] },
      setSelections,
    })

    await user.click(screen.getByRole("radio", { name: "Ricota y nuez" }))

    expect(setSelections).toHaveBeenCalledWith({ 1: [] })
  })

  it("does not let a dish be added after unselecting a required group", () => {
    renderDetail({
      item: schedule({ option_groups: groups }),
      selections: { 1: [] },
    })

    expect(screen.getByRole("button", { name: "Agregar" })).toBeDisabled()
  })

  // Criterio 1: se ofrece lo que el proveedor definió para ese plato.
  it("shows every option of every group the dish offers", () => {
    renderDetail({ item: schedule({ option_groups: groups }) })

    expect(
      screen.getByRole("radio", { name: "Ricota y nuez" }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("checkbox", { name: "Filetto" }),
    ).toBeInTheDocument()
    expect(screen.getByRole("checkbox", { name: "Rosa" })).toBeInTheDocument()
  })

  // Criterio 3: el límite del grupo se respeta en la pantalla.
  it("blocks the options left once the group limit is reached", () => {
    renderDetail({
      item: schedule({ option_groups: groups }),
      selections: { 1: ["Ricota y nuez"], 2: ["Filetto", "Puerro"] },
    })

    expect(screen.getByRole("checkbox", { name: "Rosa" })).toBeDisabled()
    expect(screen.getByRole("checkbox", { name: "Filetto" })).toBeEnabled()
  })

  it("adds a dish with no options to choose straight away", async () => {
    const user = userEvent.setup()
    const add = vi.fn()
    renderDetail({ add })

    await user.click(screen.getByRole("button", { name: "Agregar" }))

    expect(add).toHaveBeenCalledOnce()
  })

  describe("when editing an already added dish", () => {
    it("renders the 'Modificar' button and trash icon when quantity is 1", async () => {
      const user = userEvent.setup()
      const onRemove = vi.fn()
      const add = vi.fn()
      const cartItem: CartItem = {
        ...schedule(),
        cartId: "1-",
        quantity: 1,
        notes: "Sin sal",
        selections: {},
        benefits: [],
      }

      renderDetail({
        cart: [cartItem],
        editingCartId: "1-",
        quantity: 1,
        notes: "Sin sal",
        onRemove,
        add,
      })

      expect(screen.getByText("Agregado")).toBeInTheDocument()
      expect(
        screen.getByRole("button", { name: "Modificar" }),
      ).toBeInTheDocument()
      expect(
        screen.queryByRole("button", { name: "Agregar" }),
      ).not.toBeInTheDocument()

      const trashButton = screen.getByRole("button", { name: "Quitar" })
      expect(trashButton).toBeInTheDocument()

      await user.click(trashButton)
      expect(onRemove).toHaveBeenCalledOnce()
    })

    it("allows modifying the dish and clicking 'Modificar'", async () => {
      const user = userEvent.setup()
      const add = vi.fn()
      const cartItem: CartItem = {
        ...schedule(),
        cartId: "1-",
        quantity: 1,
        notes: "",
        selections: {},
        benefits: [],
      }

      renderDetail({
        cart: [cartItem],
        editingCartId: "1-",
        quantity: 2,
        onRemove: vi.fn(),
        add,
      })

      const modifyButton = screen.getByRole("button", { name: "Modificar" })
      await user.click(modifyButton)
      expect(add).toHaveBeenCalledOnce()
    })

    it("does not reduce the quota by the dish currently being edited", () => {
      const cartItem: CartItem = {
        ...schedule(),
        cartId: "1-",
        quantity: 2,
        notes: "",
        selections: {},
        benefits: [],
      }

      // Con remaining: 3 y 2 ya en el carrito para este ítem:
      // Al editarlo, el tope debe ser 3 (no 3 - 2 = 1)
      renderDetail({
        item: { ...schedule(), remaining: 3 },
        cart: [cartItem],
        editingCartId: "1-",
        quantity: 2,
        onRemove: vi.fn(),
      })

      expect(screen.getByRole("button", { name: "Agregar uno" })).toBeEnabled()
    })
  })
})

describe("benefit specials", () => {
  const special = (
    overrides: Partial<Benefit["specials"][number]> = {},
  ): Benefit["specials"][number] => ({
    id: 3,
    name: "Descuento día del padre",
    percentage: 30,
    remaining: 5,
    due_date: null,
    ...overrides,
  })

  it("shows the special and its checkbox when it has remaining units", () => {
    const s = special({ remaining: 5 })

    renderDetail({ benefit: { ...benefit, specials: [s] } })

    expect(screen.getByText(/Descuento día del padre/)).toBeInTheDocument()

    const checkbox = screen.getByRole("checkbox", { name: "Aplicar" })
    expect(checkbox).toHaveAttribute("id", `benefit-checkbox-${s.id}`)
  })

  it("does not show the special when its remaining is zero", () => {
    const s = special({ remaining: 0 })

    renderDetail({ benefit: { ...benefit, specials: [s] } })

    expect(
      screen.queryByText(/Descuento día del padre/),
    ).not.toBeInTheDocument()
    expect(
      document.getElementById(`benefit-checkbox-${s.id}`),
    ).not.toBeInTheDocument()
  })

  it("does not show a special without limit (remaining null)", () => {
    const s = special({ remaining: null })

    renderDetail({ benefit: { ...benefit, specials: [s] } })

    expect(
      screen.queryByText(/Descuento día del padre/),
    ).not.toBeInTheDocument()
    expect(
      document.getElementById(`benefit-checkbox-${s.id}`),
    ).not.toBeInTheDocument()
  })
})

describe("benefits message and lines", () => {
  it("shows the 'reached 100' message when the last line has no tier for a selectable special", async () => {
    const special = {
      id: 3,
      name: "Descuento día del padre",
      percentage: 30,
      remaining: 5,
      due_date: null,
    }

    mocks.priceItems.mockResolvedValue({
      subtotal: 320,
      discount: 0,
      total: 320,
      subsidizedQuantity: 0,
      fullPriceQuantity: 1,
      lines: [
        {
          subtotal: 320,
          discount: 0,
          total: 320,
          tiers: [], // ningún tier con id 3: el beneficio no se usó
        },
      ],
    } satisfies Pricing)

    renderDetail({ benefit: { ...benefit, specials: [special] } })

    const message = `Se llegó al 100%, no se aplicará el beneficio ${special.name}`

    expect(await screen.findByText(message)).toBeInTheDocument()
  })

  it("does not show the 'reached 100' message, but shows benefit lines", async () => {
    const special = {
      id: 3,
      name: "Descuento día del padre",
      percentage: 30,
      remaining: 5,
      due_date: null,
    }

    mocks.priceItems.mockResolvedValue({
      subtotal: 320,
      discount: 160,
      total: 160,
      subsidizedQuantity: 1,
      fullPriceQuantity: 0,
      lines: [
        {
          subtotal: 320,
          discount: 0,
          total: 320,
          tiers: [
            {
              id: 3,
              name: "Descuento día del padre",
              percentage: 30,
              quantity: 1,
              discount: 96,
            },
            {
              id: 5,
              name: "Descuento sorpresa",
              percentage: 20,
              quantity: 1,
              discount: 64,
            },
          ],
        },
      ],
    } satisfies Pricing)

    renderDetail({ benefit: { ...benefit, specials: [special] } })

    expect(await screen.findByText("- $96")).toBeInTheDocument()
    expect(await screen.findByText("- $64")).toBeInTheDocument()

    const message = `Se llegó al 100%, no se aplicará el beneficio ${special.name}`

    expect(screen.queryByText(message)).not.toBeInTheDocument()
  })
})
