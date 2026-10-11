import { render, screen } from "@testing-library/react"
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
  it("shows the invoice download in collection history", () => {
    render(<InvoiceSection account={historicalCompanyAccount} settled />)

    expect(
      screen.getByRole("link", { name: "Descargar factura" }),
    ).toHaveAttribute("href", "/provider/invoices/42/file?download=1")
  })
})
