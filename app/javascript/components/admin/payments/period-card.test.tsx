import { render, screen } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

import { Sheet } from "@/components/ui/sheet"
import type { Account, Payment } from "@/types"

import PeriodCard from "./period-card"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    usePage: () => ({ url: "/admin/pagos", props: { locale: "es" } }),
  }
})

function makePayment(overrides: Partial<Payment> = {}): Payment {
  return {
    id: 1,
    status: "submitted",
    rejection_reason: null,
    created_at: "2026-10-01T12:00:00Z",
    receipt_url: "/admin/pagos/1/archivo",
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
    vat_amount: 0,
    payable_amount: 500,
    orders_amount_sum: 2,
    orders_price_sum: 500,
    collection_status: "pending",
    payments: [],
    ...overrides,
  }
}

function renderCard(account: Account) {
  return render(
    <Sheet>
      <PeriodCard account={account} onOpenDetail={vi.fn()} />
    </Sheet>,
  )
}

describe("PeriodCard", () => {
  it("disables uploading another receipt while one is under review", () => {
    const account = makeAccount({
      collection_status: "submitted",
      payments: [makePayment({ status: "submitted" })],
    })

    renderCard(account)

    expect(
      screen.getByRole("button", { name: "Subir comprobante de pago" }),
    ).toBeDisabled()
    expect(
      screen.getByText(/Ya hay un comprobante en revisión/),
    ).toBeInTheDocument()
  })

  it("enables the upload button when there is no submitted receipt", () => {
    const account = makeAccount({
      collection_status: "rejected",
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

  it("keeps the upload button enabled when an earlier receipt was approved", () => {
    const account = makeAccount({
      collection_status: "approved",
      payments: [makePayment({ status: "approved" })],
    })

    renderCard(account)

    expect(
      screen.getByRole("button", { name: "Subir comprobante de pago" }),
    ).toBeEnabled()
    expect(
      screen.queryByText(/Ya hay un comprobante en revisión/),
    ).not.toBeInTheDocument()
  })
})
