import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import { OrderSummary } from "./order-summary"

// Es el desglose con el que el empleado decide: cuánto vale la vianda, cuánto
// cubre el beneficio y cuánto termina pagando.
describe("OrderSummary", () => {
  it("shows the price, the benefit and the amount to pay", () => {
    render(
      <OrderSummary
        subtotal={640}
        discount={320}
        total={320}
        percentage={50}
      />,
    )

    expect(screen.getByText("Precio vianda").nextSibling).toHaveTextContent(
      "$640",
    )
    expect(screen.getByText("Beneficio GoGrow (50%)")).toBeInTheDocument()
    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$320",
    )
  })

  it("keeps showing the benefit line at zero instead of hiding it", () => {
    render(
      <OrderSummary subtotal={640} discount={0} total={640} percentage={0} />,
    )

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
        discount={320}
        total={320}
        percentage={50}
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
      <OrderSummary
        subtotal={640.5}
        discount={320.4}
        total={320.1}
        percentage={50}
      />,
    )

    expect(screen.getByText("Precio vianda").nextSibling).toHaveTextContent(
      "$641",
    )
    expect(screen.getByText("Monto a pagar").nextSibling).toHaveTextContent(
      "$320",
    )
  })
})
