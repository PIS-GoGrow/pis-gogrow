import { router } from "@inertiajs/react"
import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import CollectionsShow from "@/pages/provider/collections/show"
import type { ProviderCollectionAccount } from "@/types"

import CollectionAccountDetailDialog from "./collection-account-detail-dialog"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")

  return {
    ...actual,
    Head: () => null,
    usePage: () => ({ props: { locale: "es" } }),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => children,
}))

const baseAccount = {
  id: 1,
  owner_name: "Juan Pérez",
  meals: 2,
  amount: 800,
  source: "consumer",
  status: "submitted",
  can_approve_payment: false,
  overdue: false,
  month: "Octubre 2026",
  due_date: "05/11/26",
  paid_on: null,
  payment_id: 1,
  receipt_url: "/receipt.pdf",
  receipt_content_type: "application/pdf",
  invoice: null,
  debt_reminder: {
    eligible: false,
    remaining: 10,
    next_available_at: null,
    blocked_reason: null,
  },
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
    expect(
      screen.queryByRole("link", { name: "Ver historial de pagos" }),
    ).not.toBeInTheDocument()
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

    expect(screen.getByText("Total")).toBeInTheDocument()
    expect(screen.getByText("800,00 UYU")).toBeInTheDocument()
    expect(screen.queryByText(/IVA/)).not.toBeInTheDocument()
    expect(screen.queryByText("976,00 UYU")).not.toBeInTheDocument()
    expect(screen.getByText("Pendiente")).toBeInTheDocument()
    expect(
      screen.queryByRole("link", { name: "Ver historial de pagos" }),
    ).not.toBeInTheDocument()

    await user.click(screen.getByRole("tab", { name: "Viandas" }))

    expect(screen.getByText("Milanesa con papas")).toBeInTheDocument()
  })

  it.each(["consumer", "company"] as const)(
    "links a %s account with one rejected partial payment to its history",
    async (source) => {
      const user = userEvent.setup()
      const account = {
        ...baseAccount,
        id: source === "consumer" ? 11 : 22,
        source,
        status: "rejected",
        payments: [
          {
            id: 1,
            status: "rejected",
            rejection_reason: "El pago es parcial",
            date: "02/10/26",
            receipt_url: "/receipt.pdf",
            receipt_filename: "parcial.pdf",
            receipt_content_type: "application/pdf",
          },
        ],
      } satisfies ProviderCollectionAccount

      render(<CollectionAccountDetailDialog account={account} />)
      await user.click(screen.getByRole("button", { name: "Ver detalle" }))

      expect(screen.getByText("Rechazado")).toBeInTheDocument()
      if (source === "company") {
        await user.click(screen.getByRole("tab", { name: "Viandas" }))
      }
      expect(screen.getByText("Milanesa con papas")).toBeInTheDocument()

      const link = screen.getByRole("link", { name: "Ver historial de pagos" })
      expect(link).toHaveAttribute(
        "href",
        `/provider/collections/${account.id}`,
      )

      const visit = vi
        .spyOn(router, "visit")
        .mockImplementation(() => undefined)
      await user.click(link)
      expect(visit).toHaveBeenCalledWith(
        `/provider/collections/${account.id}`,
        expect.any(Object),
      )
      visit.mockRestore()

      if (source === "company") {
        await user.click(screen.getByRole("tab", { name: "Cobro" }))
        expect(screen.getByText("800,00 UYU")).toBeInTheDocument()
        expect(screen.getByText("Rechazado")).toBeInTheDocument()
      }
    },
  )
})

describe("Collections payment history destination", () => {
  it.each(["consumer", "company"] as const)(
    "shows the date, rejected status and partial indicator for a %s account",
    (source) => {
      const payment = {
        id: 1,
        status: "rejected",
        rejection_reason: "El pago es parcial",
        date: "02/10/26",
        receipt_url: "/receipt.pdf",
        receipt_filename: "parcial.pdf",
        receipt_content_type: "application/pdf",
      } satisfies ProviderCollectionAccount["payments"][number]
      const account = {
        ...baseAccount,
        source,
        status: "rejected",
        payments: [payment],
      } satisfies ProviderCollectionAccount

      render(
        <CollectionsShow
          account={account}
          orders={account.orders}
          payments={account.payments}
        />,
      )

      expect(screen.getByText(payment.date)).toBeInTheDocument()
      expect(screen.getByText("Pago parcial")).toBeInTheDocument()
      expect(screen.getAllByText("Rechazado")).toHaveLength(2)
    },
  )
})
