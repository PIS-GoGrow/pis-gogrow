import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import { PaymentReviewResultProvider } from "@/components/payments/payment-review-result-context"
import type { ProviderCollectionAccount } from "@/types"

import CollectionAccountPanel from "./collection-account-panel"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")

  return {
    ...actual,
    usePage: () => ({ props: { locale: "es" } }),
  }
})

const account = {
  id: 1,
  owner_name: "Juan Pérez",
  meals: 2,
  amount: 800,
  source: "consumer",
  status: "pending",
  can_approve_payment: false,
  overdue: false,
  month: "Octubre 2026",
  due_date: "05/11/26",
  paid_on: null,
  payment_id: null,
  receipt_url: null,
  receipt_content_type: null,
  invoice: null,
  payments: [],
  orders: [],
} satisfies ProviderCollectionAccount

describe("CollectionAccountPanel", () => {
  it("keeps the download available for a single rejected partial payment without allowing another review", () => {
    render(
      <CollectionAccountPanel
        account={{
          ...account,
          status: "rejected",
          payments: [
            {
              id: 17,
              status: "rejected",
              rejection_reason: "El pago es parcial",
              date: "09/10/26",
              receipt_url: "/provider/payments/17/receipt",
              receipt_filename: "parcial.png",
              receipt_content_type: "image/png",
            },
          ],
        }}
      />,
    )
    expect(
      screen.getByRole("link", { name: "Descargar comprobante" }),
    ).toHaveAttribute("href", "/provider/payments/17/receipt")
    expect(
      screen.queryByRole("button", { name: "Revisar pago" }),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByRole("button", { name: "Aprobar" }),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByRole("button", { name: "Rechazar" }),
    ).not.toBeInTheDocument()
  })
  it.each(["consumer", "company"] as const)(
    "passes the expected amount and current-month restriction for a %s account",
    async (source) => {
      const user = userEvent.setup()
      render(
        <PaymentReviewResultProvider value={vi.fn()}>
          <CollectionAccountPanel
            account={{
              ...account,
              source,
              status: "submitted",
              payment_id: 17,
              receipt_url: "/provider/payments/17/receipt",
              receipt_content_type: "image/png",
            }}
          />
        </PaymentReviewResultProvider>,
      )
      await user.click(screen.getByRole("button", { name: "Revisar pago" }))
      const dialog = screen.getByRole("dialog", { name: "Comprobante" })
      expect(within(dialog).getByText("800,00 UYU")).toBeInTheDocument()
      expect(
        within(dialog).getByRole("button", { name: "Aprobar" }),
      ).toBeDisabled()
      expect(
        within(dialog).getByRole("link", { name: "Descargar comprobante" }),
      ).toHaveAttribute("href", "/provider/payments/17/receipt")
    },
  )
  it("shows a neutral due date for a pending account that is not overdue", () => {
    render(<CollectionAccountPanel account={account} />)

    const due = screen.getByText("Vence: 05/11/26")
    expect(due).toHaveClass("text-muted-foreground")
    expect(due).not.toHaveClass("text-red-600", "dark:text-red-400")
    expect(due.querySelector("svg")).not.toBeInTheDocument()
  })

  it("warns about an overdue pending account", () => {
    render(<CollectionAccountPanel account={{ ...account, overdue: true }} />)

    const due = screen.getByText("Vence: 05/11/26")
    expect(due).toHaveClass("text-red-600", "dark:text-red-400")
    expect(due.querySelector("svg")).toBeInTheDocument()
  })

  it("does not show a due date warning for an approved account", () => {
    render(
      <CollectionAccountPanel account={{ ...account, status: "approved" }} />,
    )

    expect(screen.queryByText("Vence: 05/11/26")).not.toBeInTheDocument()
    expect(screen.getByText("Octubre 2026")).toBeInTheDocument()
    expect(screen.getByText("800,00 UYU")).toBeInTheDocument()
  })

  it("shows the payment date for an approved account in the history", () => {
    render(
      <CollectionAccountPanel
        account={{ ...account, status: "approved", paid_on: "06/11/26" }}
        heading="paid_on"
      />,
    )

    expect(screen.getByText("06/11/26")).toBeInTheDocument()
    expect(screen.queryByText("Vence: 05/11/26")).not.toBeInTheDocument()
  })
})
