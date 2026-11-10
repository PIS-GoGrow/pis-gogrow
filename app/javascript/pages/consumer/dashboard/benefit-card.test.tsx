import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import type { ConsumerDashboardIndex } from "@/types"

import { BenefitCard } from "./benefit-card"

const benefit = (
  weeklyUsed: number,
  weeklyLimit: number,
): ConsumerDashboardIndex["benefit"] => ({
  percentage: 50,
  monthly_limit: 20,
  monthly_used: 7,
  monthly_remaining: 13,
  weekly_limit: weeklyLimit,
  weekly_used: weeklyUsed,
  weekly_remaining: Math.max(weeklyLimit - weeklyUsed, 0),
  specials: [],
})

describe("BenefitCard", () => {
  it("shows the subsidized meals used this week against the weekly limit", () => {
    render(<BenefitCard benefit={benefit(2, 5)} />)

    expect(screen.getByText("Esta semana")).toBeInTheDocument()
    expect(screen.getByText("2 de 5")).toBeInTheDocument()
    expect(screen.getByText("viandas pedidas")).toBeInTheDocument()
  })

  it("caps the progress when persisted usage exceeds the weekly limit", () => {
    render(<BenefitCard benefit={benefit(6, 5)} />)

    expect(screen.getByText("6 de 5")).toBeInTheDocument()
  })
})
