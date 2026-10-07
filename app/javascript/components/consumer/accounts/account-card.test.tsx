import { render, screen } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

import { Sheet } from "@/components/ui/sheet"
import type { Account, Payment } from "@/types"

import AccountCard from "./account-card"

function makePayment(overrides: Partial<Payment> = {}): Payment {
  return {
    id: 1,
    status: "submitted",
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
      <AccountCard account={account} setDetail={vi.fn()} setLoading={vi.fn()} />
    </Sheet>,
  )
}

describe("AccountCard", () => {
  it("renders yellow warning when rejection reason is partial payment", () => {
    const payment = makePayment({
      status: "rejected",
      rejection_reason: "El pago es parcial",
    })
    const account = makeAccount({ payments: [payment] })

    renderCard(account)

    expect(screen.getByText("Falta una parte del pago.")).toBeInTheDocument()
    expect(screen.queryByText(/Rechazado:/)).not.toBeInTheDocument()
  })

  it("renders red box when rejection reason is another reason", () => {
    const payment = makePayment({
      status: "rejected",
      rejection_reason: "Comprobante ilegible",
    })
    const account = makeAccount({ payments: [payment] })

    renderCard(account)

    expect(screen.getByText(/Comprobante ilegible/)).toBeInTheDocument()
    expect(
      screen.queryByText("Falta una parte del pago."),
    ).not.toBeInTheDocument()
  })

  it("hides rejection alerts when a newer receipt has been submitted", () => {
    const rejectedPayment = makePayment({
      id: 1,
      status: "rejected",
      rejection_reason: "El pago es parcial",
      created_at: "2026-10-01T12:00:00Z",
    })
    const newSubmittedPayment = makePayment({
      id: 2,
      status: "submitted",
      rejection_reason: null,
      created_at: "2026-10-02T12:00:00Z",
    })
    const account = makeAccount({
      payments: [rejectedPayment, newSubmittedPayment],
    })

    renderCard(account)

    expect(
      screen.queryByText("Falta una parte del pago."),
    ).not.toBeInTheDocument()
    expect(screen.queryByText(/Rechazado:/)).not.toBeInTheDocument()
    expect(screen.getByText("Enviado")).toBeInTheDocument()
  })
})
