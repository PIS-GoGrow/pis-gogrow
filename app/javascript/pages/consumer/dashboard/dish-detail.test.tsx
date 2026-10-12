import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import type { CartItem, Schedule } from "./consumer-types"
import { DishDetail } from "./dish-detail"
import type { Benefit } from "./pricing"

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

const benefit = (overrides: Partial<Benefit> = {}): Benefit => ({
  limit: 5,
  used: 0,
  percentage: 0,
  monthly_limit: 20,
  monthly_used: 0,
  monthly_remaining: 20,
  specials: [],
  ...overrides,
})

function renderDetail(props: Partial<Parameters<typeof DishDetail>[0]> = {}) {
  const defaults = {
    item: schedule(),
    quantity: 1,
    setQuantity: vi.fn(),
    notes: "",
    setNotes: vi.fn(),
    selections: {},
    setSelections: vi.fn(),
    benefit: benefit(),
    cart: [] as CartItem[],
    back: vi.fn(),
    add: vi.fn(),
  }
  return render(<DishDetail {...defaults} {...props} />)
}

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

  // Criterio 2: el desglose que decide la compra sale de los datos del plato y
  // del beneficio, no de un valor fijo.
  it("breaks down the price with the benefit applied", () => {
    renderDetail({
      quantity: 2,
      benefit: benefit({ percentage: 50, monthly_remaining: 20 }),
    })

    expect(screen.getByText("Precio vianda").nextSibling).toHaveTextContent(
      "$640",
    )
    expect(screen.getByText("Beneficio GoGrow (50%)")).toBeInTheDocument()
    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$320",
    )
  })

  it("subsidises only the meals left in the monthly quota", () => {
    renderDetail({
      quantity: 3,
      benefit: benefit({ percentage: 50, monthly_remaining: 1 }),
    })

    // 3 x 320 = 960, y el beneficio alcanza para una sola vianda: 160 de
    // descuento, no 480.
    expect(screen.getByText("Precio vianda").nextSibling).toHaveTextContent(
      "$960",
    )
    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$800",
    )
  })

  // IBP-037: el subsidio especial se suma al base desde el precio del plato,
  // en la misma línea "Beneficio GoGrow" con el porcentaje combinado.
  it("adds the special subsidy to the base one", () => {
    renderDetail({
      quantity: 1,
      benefit: benefit({
        percentage: 50,
        specials: [
          {
            id: 7,
            name: "Premio",
            percentage: 30,
            remaining: 2,
            due_date: null,
          },
        ],
      }),
    })

    expect(
      screen.getByText("Beneficio GoGrow (80%)").nextSibling,
    ).toHaveTextContent("- $256")
    expect(screen.queryByText("Premio (30%)")).not.toBeInTheDocument()
    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$64",
    )
  })

  it("leaves out a special that expires before the delivery date", () => {
    renderDetail({
      benefit: benefit({
        specials: [
          {
            id: 7,
            name: "Premio",
            percentage: 30,
            remaining: null,
            due_date: "2026-09-15",
          },
        ],
      }),
    })

    expect(screen.getByText("Beneficio GoGrow (0%)")).toBeInTheDocument()
    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$320",
    )
  })

  // Lo que ya está en el carrito gasta primero el cupo mensual.
  it("prices the dish after what is already in the cart", () => {
    renderDetail({
      benefit: benefit({ percentage: 50, monthly_remaining: 1 }),
      cart: [
        {
          ...schedule(),
          id: 2,
          cartId: "2-",
          quantity: 1,
          notes: "",
          selections: {},
        },
      ],
    })

    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$320",
    )
  })

  it("applies no discount when the employee has no benefit", () => {
    renderDetail({
      quantity: 2,
      benefit: benefit({ percentage: 0, monthly_remaining: 0 }),
    })

    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$640",
    )
  })

  // Criterio 1, disponibilidad: el cupo restante es el techo de lo que se puede
  // pedir, y la pantalla lo respeta.
  it("does not let the quantity go past the remaining quota", () => {
    renderDetail({ item: { ...schedule(), remaining: 2 }, quantity: 2 })

    expect(screen.getByRole("button", { name: "Agregar uno" })).toBeDisabled()
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
    },
    { id: 2, name: "salsa", options: ["Filetto", "Puerro", "Rosa"], limit: 2 },
  ]

  // IBP-022, criterio 2: no se puede pedir sin resolver lo que el plato pregunta.
  it("requires picking an option from every group before adding the dish", async () => {
    const user = userEvent.setup()
    const add = vi.fn()
    const { rerender } = renderDetail({
      item: schedule({ option_groups: groups }),
      selections: { 1: ["Ricota y nuez"] },
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
        selections={{ 1: ["Ricota y nuez"], 2: ["Filetto"] }}
        setSelections={vi.fn()}
        benefit={benefit()}
        cart={[]}
        back={vi.fn()}
        add={add}
      />,
    )

    const button = screen.getByRole("button", { name: "Agregar" })
    expect(button).toBeEnabled()
    await user.click(button)
    expect(add).toHaveBeenCalledOnce()
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
})
