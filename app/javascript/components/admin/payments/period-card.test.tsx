import { render, screen } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

import { Sheet } from "@/components/ui/sheet"
import type { AdminAccount, Payment } from "@/types"

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

function makeAccount(overrides: Partial<AdminAccount> = {}): AdminAccount {
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

function renderCard(account: AdminAccount, providerName?: string) {
  return render(
    <Sheet>
      <PeriodCard
        account={account}
        providerName={providerName}
        onOpenDetail={vi.fn()}
      />
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

  it("shows the due date in the header next to the status", () => {
    renderCard(makeAccount())

    const header = document.querySelector("[data-slot='card-header']")
    expect(header).toHaveTextContent("Vence: 10/10/26")
    expect(header?.querySelector("[data-status='pending']")).toBeInTheDocument()
  })

  // Historia IBP-061 y diseño de Figma del Historial de RR. HH.
  describe("when the payment was confirmed", () => {
    const paid = makeAccount({
      collection_status: "approved",
      paid_on: "05/09/26",
      payments: [makePayment({ status: "approved" })],
      invoice_download_url: "/rrhh/facturas/3/archivo?download=1",
      receipt_download_url: "/rrhh/pagos/1/archivo",
    })

    it("does not offer to upload another receipt", () => {
      renderCard(paid, "TuViandita")

      expect(
        screen.queryByRole("button", { name: "Subir comprobante de pago" }),
      ).not.toBeInTheDocument()
    })

    it("shows the payment date, provider, period and total paid", () => {
      renderCard(paid, "TuViandita")

      expect(screen.getByText("05/09/26")).toBeInTheDocument()
      expect(screen.getByText("Confirmado")).toBeInTheDocument()
      expect(
        screen.getByText("TuViandita: Septiembre 2026"),
      ).toBeInTheDocument()
      expect(screen.getByText("Total pagado")).toBeInTheDocument()
    })

    it("downloads the invoice and the payment receipt", () => {
      renderCard(paid, "TuViandita")

      expect(
        screen.getByRole("link", { name: "Descargar factura" }),
      ).toHaveAttribute("href", "/rrhh/facturas/3/archivo?download=1")
      expect(
        screen.getByRole("link", { name: "Descargar comprobante de pago" }),
      ).toHaveAttribute("href", "/rrhh/pagos/1/archivo")
    })

    it("leaves out the invoice download while the provider has not sent it", () => {
      renderCard({ ...paid, invoice_download_url: undefined }, "TuViandita")

      expect(
        screen.queryByRole("link", { name: "Descargar factura" }),
      ).not.toBeInTheDocument()
    })
  })
})
