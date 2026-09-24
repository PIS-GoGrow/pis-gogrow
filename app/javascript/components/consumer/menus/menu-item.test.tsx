import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import MenuItem from "./menu-item"

// IBP-003, criterio 3: "los platos agotados o no disponibles se identifican
// claramente y no pueden pedirse". Toda esa regla vive acá: soldOut viene del
// server y isPast del reloj del browser, y el componente decide con las dos si
// el plato puede llegar al pedido.
const props = {
  providerName: "Tu Viandita",
  name: "Milanesa con papas fritas",
  price: 300,
  description: "Opción de carne o pollo",
}

describe("MenuItem", () => {
  it("lets an available dish be picked", async () => {
    const user = userEvent.setup()
    const onSelect = vi.fn()
    render(<MenuItem {...props} soldOut={false} onSelect={onSelect} />)

    expect(screen.queryByText("Agotado")).not.toBeInTheDocument()

    await user.click(
      screen.getByRole("button", { name: "Agregar Milanesa con papas fritas" }),
    )

    expect(onSelect).toHaveBeenCalledOnce()
  })

  it("identifies a sold out dish and keeps it from being ordered", async () => {
    const user = userEvent.setup()
    const onSelect = vi.fn()
    render(<MenuItem {...props} soldOut onSelect={onSelect} />)

    expect(screen.getByText("Agotado")).toBeInTheDocument()

    const button = screen.getByRole("button", {
      name: "Agregar Milanesa con papas fritas",
    })
    expect(button).toBeDisabled()

    await user.click(button)
    expect(onSelect).not.toHaveBeenCalled()
  })

  // Un día ya pasado no está agotado, pero tampoco se puede pedir: son dos
  // motivos distintos para el mismo bloqueo, y el badge distingue cuál es.
  it("blocks a past dish without calling it sold out", () => {
    render(<MenuItem {...props} soldOut={false} isPast onSelect={vi.fn()} />)

    expect(screen.queryByText("Agotado")).not.toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Agregar Milanesa con papas fritas" }),
    ).toBeDisabled()
  })

  it("shows the quantity already added instead of the add icon", () => {
    render(<MenuItem {...props} soldOut={false} addedQuantity={2} />)

    expect(screen.getByText("• Agregado")).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Agregar Milanesa con papas fritas" }),
    ).toHaveTextContent("2")
  })

  it("shows the provider and the price next to the dish", () => {
    render(<MenuItem {...props} soldOut={false} />)

    expect(screen.getByText("Tu Viandita")).toBeInTheDocument()
    expect(screen.getByText(/\$300/)).toBeInTheDocument()
  })
})
