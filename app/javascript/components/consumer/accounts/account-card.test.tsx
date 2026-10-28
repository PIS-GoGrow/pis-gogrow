import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
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

const newReceipt = () =>
  new File(["contenido"], "nuevo.png", { type: "image/png" })

describe("AccountCard", () => {
  it("shows the receipt under review with its sent date and status, without the upload form", () => {
    const account = makeAccount({
      payments: [makePayment({ status: "submitted" })],
    })

    renderCard(account)

    expect(screen.getByText("receipt.png")).toBeInTheDocument()
    expect(screen.getByText("Enviado: 01/10/26")).toBeInTheDocument()
    expect(screen.getByText("En revisión")).toBeInTheDocument()
    expect(screen.queryByLabelText("Comprobante")).not.toBeInTheDocument()
    expect(
      screen.queryByRole("button", { name: "Subir comprobante de pago" }),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByText(/Ya hay un comprobante en revisión/),
    ).not.toBeInTheDocument()
  })

  it("shows the file selector with the upload button disabled until a file is chosen", async () => {
    const user = userEvent.setup()
    renderCard(makeAccount({ payments: [] }))

    const upload = screen.getByRole("button", {
      name: "Subir comprobante de pago",
    })
    expect(screen.getByText("Seleccionar archivo")).toBeInTheDocument()
    expect(upload).toBeDisabled()

    await user.upload(screen.getByLabelText("Comprobante"), newReceipt())

    expect(screen.getByText("nuevo.png")).toBeInTheDocument()
    expect(upload).toBeEnabled()
  })

  it("lets the user remove the chosen file before uploading it", async () => {
    const user = userEvent.setup()
    renderCard(makeAccount({ payments: [] }))

    await user.upload(screen.getByLabelText("Comprobante"), newReceipt())
    await user.click(screen.getByRole("button", { name: "Quitar archivo" }))

    expect(screen.queryByText("nuevo.png")).not.toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Subir comprobante de pago" }),
    ).toBeDisabled()
  })

  it("offers the selector again once the previous receipt was rejected", () => {
    const account = makeAccount({
      payments: [
        makePayment({
          status: "rejected",
          rejection_reason: "Comprobante ilegible",
        }),
      ],
    })

    renderCard(account)

    expect(screen.getByLabelText("Comprobante")).toBeEnabled()
    expect(
      screen.getByRole("button", { name: "Subir comprobante de pago" }),
    ).toBeInTheDocument()
    expect(
      screen.queryByText(/Ya hay un comprobante en revisión/),
    ).not.toBeInTheDocument()
  })

  it("keeps the selector available when an earlier payment was approved", () => {
    const account = makeAccount({
      payments: [makePayment({ status: "approved" })],
    })

    renderCard(account)

    expect(screen.getByLabelText("Comprobante")).toBeEnabled()
  })

  it("does not offer uploading while the month is still in progress", () => {
    renderCard(makeAccount({ current: true, payments: [] }))

    expect(screen.queryByLabelText("Comprobante")).not.toBeInTheDocument()
    expect(
      screen.queryByRole("button", { name: "Subir comprobante de pago" }),
    ).not.toBeInTheDocument()
  })

  it("renders yellow warning when rejection reason is partial payment", () => {
    const payment = makePayment({
      status: "rejected",
      rejection_reason: "El pago es parcial",
    })
    const account = makeAccount({ payments: [payment] })

    renderCard(account)

    expect(
      screen.getByText(
        "Falta una parte del pago. Transferí la diferencia y subí el comprobante.",
      ),
    ).toBeInTheDocument()
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
      screen.queryByText(/Falta una parte del pago/),
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
      screen.queryByText(/Falta una parte del pago/),
    ).not.toBeInTheDocument()
    expect(screen.queryByText(/Rechazado:/)).not.toBeInTheDocument()
  })

  it("shows the sent date and status of every receipt", () => {
    const account = makeAccount({
      payments: [
        makePayment({
          id: 1,
          status: "approved",
          receipt_uploaded_at: "14/08/26",
          created_at: "2026-08-14T12:00:00Z",
        }),
        makePayment({
          id: 2,
          status: "rejected",
          rejection_reason: "Comprobante ilegible",
          receipt_uploaded_at: "13/08/26",
          created_at: "2026-08-13T12:00:00Z",
        }),
      ],
    })

    renderCard(account)

    expect(screen.getByText("Enviado: 14/08/26")).toBeInTheDocument()
    expect(screen.getByText("Enviado: 13/08/26")).toBeInTheDocument()
    expect(screen.getByText("Aprobado")).toBeInTheDocument()
    expect(screen.getByText("Rechazado")).toBeInTheDocument()
  })

  it("shows the size of each receipt", () => {
    const account = makeAccount({
      payments: [
        makePayment({ status: "rejected", receipt_byte_size: 1258291 }),
      ],
    })

    renderCard(account)

    expect(screen.getByText("1.2 MB")).toBeInTheDocument()
  })
})
