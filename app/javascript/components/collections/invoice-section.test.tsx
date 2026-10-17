import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import type { ProviderCollectionAccount } from "@/types"

import InvoiceSection from "./invoice-section"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")

  return {
    ...actual,
    usePage: () => ({ props: { locale: "es" } }),
  }
})

const historicalCompanyAccount = {
  id: 1,
  owner_name: "GoGrow",
  meals: 10,
  amount: 30_000,
  vat_rate: 0.22,
  vat_amount: 6_600,
  payable_amount: 36_600,
  source: "company",
  status: "approved",
  can_approve_payment: false,
  overdue: false,
  debt_reminder: {
    eligible: false,
    remaining: 0,
    next_available_at: null,
    blocked_reason: null,
  },
  month: "Septiembre 2026",
  due_date: "05/10/26",
  paid_on: "05/09/26",
  payment_id: 10,
  receipt_url: "/provider/payments/10/receipt",
  receipt_content_type: "application/pdf",
  invoice: {
    id: 42,
    status: "approved",
    removable: false,
    total_amount: 30_000,
    issued_on: "05/09/26",
    file_name: "factura-septiembre.pdf",
    file_size: "120 KB",
  },
  orders: [],
  payments: [],
} satisfies ProviderCollectionAccount

describe("InvoiceSection", () => {
  it("uses the company payable amount as the suggested invoice total", async () => {
    const user = userEvent.setup()
    const account = {
      ...historicalCompanyAccount,
      status: "pending",
      invoice: null,
    } satisfies ProviderCollectionAccount

    render(<InvoiceSection account={account} />)

    await user.upload(
      screen.getByLabelText("Archivo de la factura"),
      new File(["invoice"], "factura.pdf", { type: "application/pdf" }),
    )
    await user.click(screen.getByRole("button", { name: "Subir factura" }))

    expect(screen.getByLabelText("Monto total")).toHaveValue(36_600)
    expect(screen.getByText(/36\.600,00 UYU/)).toBeInTheDocument()
  })

  it("shows the invoice download in collection history", () => {
    render(<InvoiceSection account={historicalCompanyAccount} settled />)

    expect(
      screen.getByRole("link", { name: "Descargar factura" }),
    ).toHaveAttribute("href", "/provider/invoices/42/file?download=1")
  })
})
