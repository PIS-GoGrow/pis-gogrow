import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import type { ProviderCollectionAccount } from "@/types"

import CollectionAccountDetailDialog from "./collection-account-detail-dialog"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")

  return {
    ...actual,
    usePage: () => ({ props: { locale: "es" } }),
  }
})

const baseAccount = {
  id: 1,
  owner_name: "Juan Pérez",
  meals: 2,
  amount: 800,
  source: "consumer",
  status: "submitted",
  overdue: false,
  month: "Octubre 2026",
  due_date: "05/11/26",
  paid_on: null,
  payment_id: 1,
  receipt_url: "/receipt.pdf",
  receipt_content_type: "application/pdf",
  invoice: null,
  payments: [],
  orders: [
    {
      id: 10,
      amount: 2,
      menu_name: "Milanesa con papas",
      consumer_name: "Juan Pérez",
      delivery_date: "02/10/26",
      charged: 800,
      subsidy: 800,
    },
  ],
} satisfies ProviderCollectionAccount

describe("CollectionAccountDetailDialog", () => {
  it("shows the employee consumption history", async () => {
    const user = userEvent.setup()
    render(<CollectionAccountDetailDialog account={baseAccount} />)

    await user.click(screen.getByRole("button", { name: "Ver detalle" }))

    expect(
      screen.getByText("Historial de consumo: Octubre 2026"),
    ).toBeInTheDocument()
    expect(screen.getByText("Milanesa con papas")).toBeInTheDocument()
    expect(screen.getByText("Total: 800,00 UYU")).toBeInTheDocument()
    expect(screen.getByText("En revisión")).toBeInTheDocument()
  })

  it("shows collection totals and meals for a company", async () => {
    const user = userEvent.setup()
    const company = {
      ...baseAccount,
      id: 2,
      owner_name: "GoGrow",
      source: "company",
      status: "pending",
    } satisfies ProviderCollectionAccount

    render(<CollectionAccountDetailDialog account={company} />)
    await user.click(screen.getByRole("button", { name: "Ver detalle" }))

    expect(screen.getByText("Subtotal sin IVA")).toBeInTheDocument()
    expect(screen.getByText("176,00 UYU")).toBeInTheDocument()
    expect(screen.getByText("976,00 UYU")).toBeInTheDocument()
    expect(screen.getByText("Pendiente")).toBeInTheDocument()

    await user.click(screen.getByRole("tab", { name: "Viandas" }))

    expect(screen.getByText("Milanesa con papas")).toBeInTheDocument()
  })
})
