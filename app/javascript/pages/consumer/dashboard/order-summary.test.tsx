import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import { OrderSummary } from "./order-summary"
import type { DiscountTier } from "./pricing"

const tier = (percentage: number, discount: number): DiscountTier => ({
  percentage,
  quantity: discount > 0 ? 1 : 0,
  discount,
})

// Es el desglose con el que el empleado decide: cuánto vale la vianda, cuánto
// cubre el beneficio y cuánto termina pagando.
describe("OrderSummary", () => {
  // IBP-037: el porcentaje es el combinado (base + especiales), en una sola
  // línea como en Figma; si las viandas tienen porcentajes distintos, una
  // línea por porcentaje.
  it("shows one benefit line per combined percentage", () => {
    render(
      <OrderSummary
        subtotal={960}
        total={384}
        tiers={[
          { percentage: 80, quantity: 1, discount: 256 },
          { percentage: 50, quantity: 2, discount: 320 },
        ]}
      />,
    )

    expect(
      screen.getByText("Beneficio GoGrow (80%)").nextSibling,
    ).toHaveTextContent("- $256")
    expect(
      screen.getByText("Beneficio GoGrow (50%)").nextSibling,
    ).toHaveTextContent("- $320")
    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$384",
    )
  })

  it("shows the price, the benefit and the amount to pay", () => {
    render(<OrderSummary subtotal={640} total={320} tiers={[tier(50, 320)]} />)

    expect(screen.getByText("Precio vianda").nextSibling).toHaveTextContent(
      "$640",
    )
    expect(screen.getByText("Beneficio GoGrow (50%)")).toBeInTheDocument()
    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$320",
    )
  })

  it("keeps showing the benefit line at zero instead of hiding it", () => {
    render(<OrderSummary subtotal={640} total={640} tiers={[tier(0, 0)]} />)

    expect(screen.getByText("Beneficio GoGrow (0%)")).toBeInTheDocument()
    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$640",
    )
  })

  // En modo compacto solo queda el monto final: el desglose no se muestra, y no
  // se reemplaza por otra cosa.
  it("shows only the amount to pay when compact", () => {
    render(
      <OrderSummary
        subtotal={640}
        total={320}
        tiers={[tier(50, 320)]}
        compact
      />,
    )

    expect(screen.queryByText("Precio vianda")).not.toBeInTheDocument()
    expect(screen.queryByText("Beneficio GoGrow (50%)")).not.toBeInTheDocument()
    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$320",
    )
  })

  it("rounds the amounts it shows", () => {
    render(
      <OrderSummary subtotal={640.5} total={320.1} tiers={[tier(50, 320.4)]} />,
    )

    expect(screen.getByText("Precio vianda").nextSibling).toHaveTextContent(
      "$641",
    )
    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$320",
    )
  })
})
