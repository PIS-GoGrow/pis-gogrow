import { fireEvent, render, screen, waitFor } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import type { Account, AdminPaymentsIndex } from "@/types"

import Index from "./index"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    usePage: () => ({ url: "/admin/payments", props: { locale: "es" } }),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

const props: AdminPaymentsIndex = {
  accounts: [],
  history: [],
  total_debt: 0,
  total_meals: 0,
  current_month: { amount: 0, meals: 0, limit: null },
  period: null,
  current_period: null,
  providers: [],
}

const provider = (id: number, name: string) => ({
  id,
  name,
  meals: 108,
  subtotal: 16200,
  vat_rate: 22,
  vat_amount: 3564,
  payable_amount: 19764,
  days: [],
})

const period: NonNullable<AdminPaymentsIndex["period"]> = {
  month: "Agosto 2026",
  tab: "history",
  providers: [provider(1, "Endulzate by Noe"), provider(2, "Tu Viandita")],
}

const account: Account = {
  id: 7,
  provider_id: 2,
  amount: 15000,
  vat_amount: 0,
  payable_amount: 15000,
  current: false,
  month: "agosto de 2026",
  due_date: "10/09/26",
  due_date_passed: false,
  collection_status: "pending",
  orders_amount_sum: 100,
  orders_price_sum: 15000,
  payments: [],
}

// Historia IBP-032: "Ver detalle del consumo" del inicio abre en Pagos el
// período elegido.
describe("Admin Payments Page", () => {
  it("opens the detail of the period the home asked for", () => {
    render(<Index {...props} period={period} />)

    expect(screen.getByRole("dialog")).toHaveTextContent(
      "Endulzate by Noe: Consumo Agosto 2026",
    )
    expect(
      // El panel es modal: Radix esconde lo de atrás del árbol accesible.
      screen.getByRole("tab", { name: "Historial", hidden: true }),
    ).toHaveAttribute("aria-selected", "true")
  })

  it("shows the consumption of the month as in the design", () => {
    render(
      <Index
        {...props}
        current_month={{ amount: 2100, meals: 14, limit: 300 }}
      />,
    )

    expect(screen.getByText("Tu consumo")).toBeInTheDocument()
    expect(screen.getByText("$2.100")).toBeInTheDocument()
    expect(
      screen.getByText("| 14 de 300 viandas consumidas"),
    ).toBeInTheDocument()
    expect(screen.getByRole("progressbar")).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Ver detalle del consumo" }),
    ).toBeDisabled()
  })

  it("opens the detail of the current month from the consumption card", () => {
    render(<Index {...props} current_period={{ ...period, tab: "pending" }} />)

    fireEvent.click(
      screen.getByRole("button", { name: "Ver detalle del consumo" }),
    )

    expect(screen.getByRole("dialog")).toHaveTextContent(
      "Endulzate by Noe: Consumo Agosto 2026",
    )
  })

  it("starts closed on the pending tab without a period", () => {
    render(<Index {...props} />)

    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
    expect(screen.getByRole("tab", { name: "Pendientes" })).toHaveAttribute(
      "aria-selected",
      "true",
    )
  })

  it("opens the detail of a period with its provider already chosen", async () => {
    vi.stubGlobal(
      "fetch",
      vi
        .fn()
        .mockResolvedValue({ ok: true, json: () => Promise.resolve(period) }),
    )

    render(
      <Index
        {...props}
        accounts={[account]}
        providers={[
          {
            id: 2,
            name: "Tu Viandita",
            home_delivery: true,
            bank_name: null,
            bank_account_number: null,
            bank_account_holder: null,
          },
        ]}
      />,
    )

    fireEvent.click(screen.getByRole("button", { name: "Ver detalle" }))

    await waitFor(() =>
      expect(screen.getByRole("dialog")).toHaveTextContent(
        "Tu Viandita: Consumo Agosto 2026",
      ),
    )
    expect(fetch).toHaveBeenCalledWith("/admin/payments/7", expect.anything())

    vi.unstubAllGlobals()
  })

  it("shows the meals next to the pending total", () => {
    render(<Index {...props} total_debt={19500} total_meals={130} />)

    expect(screen.getByText("$19.500")).toBeInTheDocument()
    expect(screen.getByText("(130 viandas)")).toBeInTheDocument()
  })

  it("shows the status the server resolved for each period", () => {
    const payment = {
      rejection_reason: null,
      receipt_uploaded_at: "01/09/2026",
    }

    render(
      <Index
        {...props}
        accounts={[
          {
            ...account,
            collection_status: "submitted",
            payments: [
              {
                ...payment,
                id: 1,
                status: "submitted",
                created_at: "2026-09-01T10:00:00Z",
              },
              {
                ...payment,
                id: 2,
                status: "approved",
                created_at: "2026-09-02T10:00:00Z",
              },
            ],
          },
        ]}
        providers={[
          {
            id: 2,
            name: "Tu Viandita",
            home_delivery: true,
            bank_name: null,
            bank_account_number: null,
            bank_account_holder: null,
          },
        ]}
      />,
    )

    expect(
      document.querySelector("[data-slot='card-header'] [data-status]"),
    ).toHaveAttribute("data-status", "submitted")
  })
})
