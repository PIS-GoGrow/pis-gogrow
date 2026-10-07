import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import { Sheet } from "@/components/ui/sheet"
import { PARTIAL_PAYMENT_REJECTION_REASON } from "@/lib/payment-rejection-reasons"
import type { Account, Payment } from "@/types"

import PaymentHistoryCard from "./payment-history-card"

function makePayment(overrides: Partial<Payment> = {}): Payment {
  return {
    id: 1,
    status: "approved",
    rejection_reason: null,
    created_at: "2026-10-01T12:00:00Z",
    receipt_url: "/payments/1/receipt",
    receipt_filename: "receipt.png",
    receipt_uploaded_at: "01/10/26",
    ...overrides,
  }
}

function makeAccount(overrides: Partial<Account> = {}): Account {
  return {
    id: 10,
    provider_id: 1,
    current: false,
    month: "Septiembre 2026",
    due_date: "10/10/26",
    due_date_passed: false,
    amount: 500,
    orders_amount_sum: 2,
    orders_price_sum: 500,
    payments: [],
    ...overrides,
  }
}

function renderCard(account: Account) {
  return render(
    <Sheet>
      <PaymentHistoryCard
        account={account}
        setDetail={vi.fn()}
        setLoading={vi.fn()}
      />
    </Sheet>,
  )
}

describe("PaymentHistoryCard", () => {
  it("renders a disabled download button when there are no receipts", () => {
    const account = makeAccount({ payments: [] })

    renderCard(account)

    const button = screen.getByRole("button", {
      name: /Descargar comprobante de pago/i,
    })
    expect(button).toBeDisabled()
  })

  it("renders a single download link when there is exactly one receipt", () => {
    const payment = makePayment({
      receipt_url: "/payments/1/receipt",
      receipt_filename: "comprobante_unico.pdf",
    })
    const account = makeAccount({ payments: [payment] })

    renderCard(account)

    const link = screen.getByRole("link", {
      name: /Descargar comprobante de pago/i,
    })
    expect(link).toHaveAttribute("href", "/payments/1/receipt")
    expect(link).toHaveAttribute("download")
  })

  it("renders a collapsible button and lists all receipts when there are multiple", async () => {
    const user = userEvent.setup()
    const payment1 = makePayment({
      id: 1,
      status: "rejected",
      rejection_reason: PARTIAL_PAYMENT_REJECTION_REASON,
      created_at: "2026-09-15T10:00:00Z",
      receipt_url: "/payments/1/receipt",
      receipt_filename: "comprobante_parcial.png",
      receipt_uploaded_at: "15/09/26",
    })
    const payment2 = makePayment({
      id: 2,
      status: "approved",
      rejection_reason: null,
      created_at: "2026-09-20T10:00:00Z",
      receipt_url: "/payments/2/receipt",
      receipt_filename: "comprobante_final.png",
      receipt_uploaded_at: "20/09/26",
    })
    const account = makeAccount({ payments: [payment1, payment2] })

    renderCard(account)

    // Should not render the single download button directly
    expect(
      screen.queryByRole("link", { name: /Descargar comprobante de pago/i }),
    ).not.toBeInTheDocument()

    const seeReceiptsButton = screen.getByRole("button", {
      name: /Ver comprobantes/i,
    })
    expect(seeReceiptsButton).toBeInTheDocument()

    // Expand the collapsible
    await user.click(seeReceiptsButton)

    // Both receipts should be visible
    expect(screen.getByText("comprobante_parcial.png")).toBeInTheDocument()
    expect(screen.getByText("comprobante_final.png")).toBeInTheDocument()

    // Partial payment badge is rendered
    expect(screen.getByText("Pago parcial")).toBeInTheDocument()

    // Download buttons/links for both
    const downloadLinks = screen.getAllByRole("link", {
      name: /Descargar comprobante/i,
    })
    expect(downloadLinks).toHaveLength(2)
  })
})
