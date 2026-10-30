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
    usePage: () => ({
      props: { auth: { user: { name: "Sofía" } }, locale: "es" },
    }),
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
    payment_details_complete: true,
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

  it("renders pending account cards in descending order from newest to oldest month", () => {
    const newerAccount = {
      id: 101,
      provider_id: 1,
      amount: 450,
      vat_amount: 0,
      payable_amount: 450,
      current: true,
      month: "Octubre de 2026",
      due_date: "10/11/2026",
      due_date_passed: false,
      collection_status: "pending" as const,
      orders_amount_sum: 2,
      orders_price_sum: 450,
      payments: [],
    }

    const olderAccount = {
      id: 102,
      provider_id: 1,
      amount: 600,
      vat_amount: 0,
      payable_amount: 600,
      current: false,
      month: "Setiembre de 2026",
      due_date: "10/10/2026",
      due_date_passed: true,
      collection_status: "pending" as const,
      orders_amount_sum: 3,
      orders_price_sum: 600,
      payments: [],
    }

    render(
      <Index
        accounts={[newerAccount, olderAccount]}
        history_accounts={[]}
        providers={defaultProviders}
        history={false}
        current_month_debt={450}
        total_debt={1050}
        benefit_used={2}
        benefit_available={20}
      />,
    )

    const monthElements = screen.getAllByText(/(Octubre|Setiembre) de 2026/)
    expect(monthElements[0].textContent).toContain("Octubre de 2026")
    expect(monthElements[1].textContent).toContain("Setiembre de 2026")
  })

  it("shows 'En revisión' consistently in both the card badge and receipt section when payment is submitted", () => {
    const submittedAccount = {
      id: 103,
      provider_id: 1,
      amount: 300,
      vat_amount: 0,
      payable_amount: 300,
      current: false,
      month: "Setiembre de 2026",
      due_date: "10/10/2026",
      due_date_passed: false,
      collection_status: "submitted" as const,
      orders_amount_sum: 1,
      orders_price_sum: 300,
      payments: [
        {
          id: 50,
          status: "submitted" as const,
          receipt_url: "/uploads/receipt.png",
          created_at: "2026-10-05T12:00:00Z",
          rejection_reason: null,
          receipt_uploaded_at: "2026-10-05T12:00:00Z",
        },
      ],
    }

    render(
      <Index
        accounts={[submittedAccount]}
        history_accounts={[]}
        providers={defaultProviders}
        history={false}
        current_month_debt={0}
        total_debt={300}
        benefit_used={0}
        benefit_available={20}
      />,
    )

    const badges = screen.getAllByText("En revisión")
    expect(badges).toHaveLength(2)
    expect(badges[0]).toBeInTheDocument()
    expect(badges[1]).toBeInTheDocument()
  })
})
