import { render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import type { PaymentProvider } from "@/types"

import Index from "./index"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    router: { flushAll: vi.fn() },
    usePage: () => ({ props: { auth: { user: { name: "Sofía" } }, locale: "es" } }),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

const defaultProviders: PaymentProvider[] = [
  {
    id: 1,
    name: "Tu Viandita",
    bank_name: "Banco República",
    bank_account_number: "00123456",
    bank_account_holder: "Tu Viandita SRL",
    home_delivery: true,
  },
]

describe("Consumer Accounts Index Page", () => {
  it("shows the subsidized meals used this month against the monthly limit", () => {
    render(
      <Index
        accounts={[]}
        history_accounts={[]}
        providers={defaultProviders}
        history={false}
        current_month_debt={500}
        total_debt={500}
        benefit_used={3}
        benefit_available={20}
      />,
    )

    expect(screen.getByText(/3 de 20 viandas/)).toBeInTheDocument()
  })

  it("uses singular 'vianda' when the available benefit is 1", () => {
    render(
      <Index
        accounts={[]}
        history_accounts={[]}
        providers={defaultProviders}
        history={false}
        current_month_debt={0}
        total_debt={0}
        benefit_used={1}
        benefit_available={1}
      />,
    )

    expect(screen.getByText(/1 de 1 vianda/)).toBeInTheDocument()
  })

  it("displays zero meals used when no monthly benefit has been consumed", () => {
    render(
      <Index
        accounts={[]}
        history_accounts={[]}
        providers={defaultProviders}
        history={false}
        current_month_debt={0}
        total_debt={0}
        benefit_used={0}
        benefit_available={20}
      />,
    )

    expect(screen.getByText(/0 de 20 viandas/)).toBeInTheDocument()
  })
})
