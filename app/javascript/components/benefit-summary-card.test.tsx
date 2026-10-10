import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import BenefitSummaryCard from "./benefit-summary-card"

// IBP-037: la Cuenta del empleado y su ficha en RRHH muestran el descuento
// total (base + especiales) y de dónde sale.
describe("BenefitSummaryCard", () => {
  it("shows the combined discount and its breakdown", () => {
    render(
      <BenefitSummaryCard
        title="Beneficio"
        empty="Sin beneficio vigente"
        summary={{
          total: 75,
          base: 50,
          specials: [{ name: "Antigüedad (5 años)", percentage: 25 }],
        }}
      />,
    )

    expect(screen.getByText("Activo")).toBeInTheDocument()
    expect(screen.getByText("75%")).toBeInTheDocument()
    expect(screen.getByText("de descuento en viandas")).toBeInTheDocument()
    expect(screen.getByText("Subsidio Base").nextSibling).toHaveTextContent(
      "50%",
    )
    expect(
      screen.getByText("Antigüedad (5 años)").nextSibling,
    ).toHaveTextContent("25%")
  })

  it("leaves out the base row for an employee with only special subsidies", () => {
    render(
      <BenefitSummaryCard
        title="Beneficio"
        empty="Sin beneficio vigente"
        summary={{
          total: 30,
          base: 0,
          specials: [{ name: "Premio", percentage: 30 }],
        }}
      />,
    )

    expect(screen.queryByText("Subsidio Base")).not.toBeInTheDocument()
    expect(screen.getByText("Premio").nextSibling).toHaveTextContent("30%")
  })

  it("explains there is no benefit instead of showing a 0%", () => {
    render(
      <BenefitSummaryCard
        title="Beneficio"
        empty="Sin beneficio vigente"
        summary={null}
      />,
    )

    expect(screen.getByText("Sin beneficio")).toBeInTheDocument()
    expect(screen.getByText("Sin beneficio vigente")).toBeInTheDocument()
    expect(screen.queryByText(/%/)).not.toBeInTheDocument()
  })
})
