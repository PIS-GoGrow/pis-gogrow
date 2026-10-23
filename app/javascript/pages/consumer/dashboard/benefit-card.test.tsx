import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import type { ConsumerDashboardIndex } from "@/types"

import { BenefitCard } from "./benefit-card"

const benefit = (
  monthlyUsed: number,
  monthlyLimit: number,
): ConsumerDashboardIndex["benefit"] => ({
  percentage: 50,
  monthly_limit: monthlyLimit,
  monthly_used: monthlyUsed,
  monthly_remaining: Math.max(monthlyLimit - monthlyUsed, 0),
  specials: [],
})

// El beneficio es mensual: la tarjeta no inventa un tope semanal.
describe("BenefitCard", () => {
  it("shows the subsidized meals used this month against the monthly limit", () => {
    render(<BenefitCard benefit={benefit(3, 2)} />)

    expect(screen.getByText("Este mes")).toBeInTheDocument()
    expect(screen.getByText("3 de 2")).toBeInTheDocument()
    expect(screen.getByText("viandas subsidiadas")).toBeInTheDocument()
  })

  it("does not divide a small monthly limit down to zero", () => {
    render(<BenefitCard benefit={benefit(1, 3)} />)

    expect(screen.getByText("1 de 3")).toBeInTheDocument()
  })
})
