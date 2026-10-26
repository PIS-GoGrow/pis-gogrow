import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import type {
  ProviderCollectionAccount,
  ProviderCollectionGroup,
} from "@/types"

import CollectionGroupCard from "./collection-group-card"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")

  return {
    ...actual,
    usePage: () => ({ props: { locale: "es" } }),
  }
})

const company = {
  id: 1,
  owner_name: "GoGrow",
  meals: 3,
  amount: 1000,
  vat_rate: 0,
  vat_amount: 0,
  payable_amount: 1000,
  source: "company",
  status: "pending",
  can_approve_payment: false,
  overdue: false,
  month: "Septiembre 2026",
  due_date: "10/10/26",
  paid_on: null,
  payment_id: null,
  receipt_url: null,
  receipt_content_type: null,
  invoice: {
    id: 5,
    status: "pending",
    removable: true,
    total_amount: 1000,
    issued_on: "01/10/26",
    file_name: "factura.pdf",
    file_size: "594 Bytes",
  },
  debt_reminder: {
    eligible: false,
    remaining: 10,
    next_available_at: null,
    blocked_reason: null,
  },
  payments: [],
  orders: [],
} satisfies ProviderCollectionAccount

function groupWith(account: ProviderCollectionAccount) {
  return {
    key: "1-2026-09",
    meals: 3,
    awaiting_count: 0,
    rejected_count: 0,
    client_id: 1,
    client_name: "GoGrow",
    month: "Septiembre 2026",
    total: 1000,
    confirmed_total: 0,
    employees_total: 0,
    employees_status: null,
    company: account,
    employees: [],
  } satisfies ProviderCollectionGroup
}

async function openCompany() {
  await userEvent.click(screen.getByRole("button", { name: /Empresa/ }))
}

describe("CollectionGroupCard", () => {
  it("muestra el estado de la factura en el mes de Empresa mientras se espera el cobro", async () => {
    render(<CollectionGroupCard group={groupWith(company)} />)
    await openCompany()

    expect(screen.getByText("En revisión")).toBeInTheDocument()
    expect(screen.queryByText("Vence: 10/10/26")).not.toBeInTheDocument()
  })

  it("no muestra el estado de la factura cuando se rechazó el comprobante de Empresa", async () => {
    render(
      <CollectionGroupCard
        group={groupWith({
          ...company,
          status: "rejected",
          payments: [
            {
              id: 17,
              status: "rejected",
              rejection_reason: "El comprobante no corresponde",
              date: "09/10/26",
              receipt_url: "/provider/comprobantes/17/archivo",
              receipt_filename: "comprobante.png",
              receipt_content_type: "image/png",
            },
          ],
        })}
      />,
    )
    await openCompany()

    expect(screen.queryByText("En revisión")).not.toBeInTheDocument()
    expect(screen.getByText("Vence: 10/10/26")).toBeInTheDocument()
  })
})
