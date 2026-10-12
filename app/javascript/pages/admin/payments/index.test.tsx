import { render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import type { AdminPaymentsIndex } from "@/types"

import Index from "./index"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    usePage: () => ({ url: "/admin/payments", props: { locale: "es" } }),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

const props: AdminPaymentsIndex = {
  accounts: [],
  history: [],
  total_debt: 0,
  current_month: { amount: 0, meals: 0, limit: null },
  period: null,
  providers: [],
}

const period: NonNullable<AdminPaymentsIndex["period"]> = {
  orders: [
    { id: 1, date: "04/08/2026", menu_name: "Milanesa", amount: 1, price: 300 },
  ],
  month: "agosto de 2026",
  amount: 1250,
  tab: "history",
}

// Historia IBP-032: "Ver detalle del consumo" del inicio abre en Pagos el
// período elegido.
describe("Admin Payments Page", () => {
  it("opens the detail of the period the home asked for", () => {
    render(<Index {...props} period={period} />)

    expect(screen.getByRole("dialog")).toHaveTextContent("agosto de 2026")
    expect(
      // El panel es modal: Radix esconde lo de atrás del árbol accesible.
      screen.getByRole("tab", { name: "Historial", hidden: true }),
    ).toHaveAttribute("aria-selected", "true")
  })

  it("starts closed on the pending tab without a period", () => {
    render(<Index {...props} />)

    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
    expect(screen.getByRole("tab", { name: "Pendientes" })).toHaveAttribute(
      "aria-selected",
      "true",
    )
  })
})
