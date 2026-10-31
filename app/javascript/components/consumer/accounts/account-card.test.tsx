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
    receipt_url: "/comprobantes/1/archivo",
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
    collection_status: "pending",
    amount: 500,
    vat_amount: 0,
    payable_amount: 500,
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
  it("disables uploading another receipt while one is under review", () => {
    const account = makeAccount({
      payments: [makePayment({ status: "submitted" })],
    })

    renderCard(account)

    expect(screen.getByText("receipt.png")).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Subir comprobante de pago" }),
    ).toBeDisabled()
    expect(
      screen.getByText(/Ya hay un comprobante en revisión/),
    ).toBeInTheDocument()
  })

  it("offers uploading another receipt once the previous one was rejected", () => {
    const account = makeAccount({
      payments: [
        makePayment({
          status: "rejected",
          rejection_reason: "Comprobante ilegible",
        }),
      ],
    })

    renderCard(account)

    expect(
      screen.getByRole("button", { name: "Subir comprobante de pago" }),
    ).toBeEnabled()
    expect(
      screen.queryByText(/Ya hay un comprobante en revisión/),
    ).not.toBeInTheDocument()
  })

  it("does not offer another upload when the account is already approved", () => {
    const account = makeAccount({
      collection_status: "approved",
      payments: [makePayment({ status: "approved" })],
    })

    renderCard(account)

    expect(
      screen.queryByRole("button", { name: "Subir comprobante de pago" }),
    ).not.toBeInTheDocument()
  })

  it("renders partial as an independent status with the incomplete-payment warning", () => {
    const payment = makePayment({
      status: "partial",
      rejection_reason: null,
    })
    const account = makeAccount({
      collection_status: "partial",
      payments: [payment],
    })

    renderCard(account)

    expect(screen.getAllByText("Pago parcial").length).toBeGreaterThan(0)
    expect(screen.getByText("Falta una parte del pago.")).toBeInTheDocument()
    expect(screen.queryByText("Rechazado")).not.toBeInTheDocument()
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

  it("presents a historical partial rejection without changing its upload rules", () => {
    const payment = makePayment({
      status: "rejected",
      rejection_reason: "El pago es parcial",
    })
    const account = makeAccount({ payments: [payment] })

    renderCard(account)

    expect(screen.getAllByText("Pago parcial").length).toBeGreaterThan(0)
    expect(screen.getByText("Falta una parte del pago.")).toBeInTheDocument()
    expect(screen.queryByText("Rechazado")).not.toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Subir comprobante de pago" }),
    ).toBeEnabled()
  })

  it("hides rejection alerts when a newer receipt has been submitted", () => {
    const partialPayment = makePayment({
      id: 1,
      status: "partial",
      rejection_reason: null,
      created_at: "2026-10-01T12:00:00Z",
    })
    const newSubmittedPayment = makePayment({
      id: 2,
      status: "submitted",
      rejection_reason: null,
      created_at: "2026-10-02T12:00:00Z",
    })
    const account = makeAccount({
      payments: [partialPayment, newSubmittedPayment],
    })

    renderCard(account)

    expect(
      screen.queryByText("Falta una parte del pago."),
    ).not.toBeInTheDocument()
    expect(screen.queryByText(/Rechazado:/)).not.toBeInTheDocument()
    // La tarjeta muestra "En revisión" dos veces: el estado de la cuenta y el
    // del comprobante enviado.
    expect(screen.getAllByText("En revisión")).toHaveLength(2)
  })
})
