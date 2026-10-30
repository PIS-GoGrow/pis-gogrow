import { fireEvent, render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import { render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import type { PaymentProvider } from "@/types"

import Index from "./index"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    router: { flushAll: vi.fn() },
    usePage: () => ({ url: "/payments",
      props: { auth: { user: { name: "Sofía" } }, locale: "es" },
    }),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

const detail = {
  month: "Octubre 2026",
  amount: 450.75,
  orders: [
    {
      id: 1,
      amount: 2,
      price: 300.5,
      date: "30/10/26",
      menu_name: "Milanesa al pan",
    },
    {
      id: 2,
      amount: 1,
      price: 150.25,
      date: "20/10/26",
      menu_name: "Tarta de jamón",
    },
  ],
}

const props = {
  accounts: [],
  history_accounts: [],
  providers: [],
  history: false,
  current_month_debt: 450.75,
  current_month_ordered: 3,
  current_month_detail: detail,
  total_debt: 0,
  total_meals: 0,
  benefit_available: 20,
}

describe("Consumer Payments Page", () => {
  it("shows the consumption of the month against the benefit limit", () => {
    render(<Index {...props} />)

    expect(screen.getByText("Tu consumo")).toBeInTheDocument()
    expect(screen.getByText("$450,75")).toBeInTheDocument()
    expect(screen.getByText("| 3 de 20 viandas consumidas")).toBeInTheDocument()
    expect(screen.getByRole("progressbar")).toBeInTheDocument()
  })

  it("leaves out the progress bar when the employee has no monthly benefit", () => {
    render(<Index {...props} benefit_available={0} />)

    expect(screen.getByText("| 3 viandas consumidas")).toBeInTheDocument()
    expect(screen.queryByRole("progressbar")).not.toBeInTheDocument()
  })

  it("opens the orders of the month from the consumption card", () => {
    render(<Index {...props} />)

    fireEvent.click(
      screen.getByRole("button", { name: "Ver detalle del consumo" }),
    )

    const dialog = screen.getByRole("dialog")
    expect(dialog).toHaveTextContent("Consumo Octubre 2026")
    expect(dialog).toHaveTextContent("Milanesa al pan")
    expect(dialog).toHaveTextContent("Tarta de jamón")
    expect(dialog).not.toHaveTextContent("Total")
  })

  it("shows how many meals the pending debt covers", () => {
    render(<Index {...props} total_debt={450} total_meals={3} />)

    expect(screen.getByText("(3 viandas)")).toBeInTheDocument()
  })

  it("uses the singular for one pending meal and shows zero without debt", () => {
    const { rerender } = render(
      <Index {...props} total_debt={150} total_meals={1} />,
    )

    expect(screen.getByText("(1 vianda)")).toBeInTheDocument()

    rerender(<Index {...props} />)

    expect(screen.getByText("(0 viandas)")).toBeInTheDocument()
  })

  it("disables the detail button while there is no consumption", () => {
    render(
      <Index
        {...props}
        current_month_ordered={0}
        current_month_detail={{ ...detail, orders: [], amount: 0 }}
      />,
    )

    expect(
      screen.getByRole("button", { name: "Ver detalle del consumo" }),
    ).toBeDisabled()
  })

  describe("history tab", () => {
    const provider = (id: number, name: string) => ({
      id,
      name,
      home_delivery: true,
      bank_name: null,
      bank_account_number: null,
      bank_account_holder: null,
    })

    const closedPeriod = (
      id: number,
      provider_id: number,
      month: string,
      due_date: string,
    ) => ({
      id,
      provider_id,
      month,
      due_date,
      current: false,
      due_date_passed: true,
      collection_status: "approved" as const,
      amount: 700,
      vat_amount: 0,
      payable_amount: 700,
      orders_amount_sum: 5,
      orders_price_sum: 700,
      payments: [],
    })

    const historyProps = {
      ...props,
      history: true,
      providers: [
        provider(1, "Tu Viandita"),
        provider(2, "Endulzate by Noe"),
        provider(3, "Sin pagos"),
      ],
      history_accounts: [
        closedPeriod(1, 2, "Agosto 2026", "05/09/26"),
        closedPeriod(2, 1, "Julio 2026", "05/08/26"),
      ],
    }

    it("lists the closed periods with their date, provider and month", () => {
      render(<Index {...historyProps} />)

      expect(screen.getByText("Proveedores:")).toBeInTheDocument()
      expect(screen.getByText("Todos")).toBeInTheDocument()
      expect(screen.getByText("05/09/26")).toBeInTheDocument()
      expect(
        screen.getByText("Endulzate by Noe: Agosto 2026"),
      ).toBeInTheDocument()
      expect(screen.getByText("05/08/26")).toBeInTheDocument()
      expect(screen.getByText("Tu Viandita: Julio 2026")).toBeInTheDocument()
      expect(screen.getAllByText("Confirmado")).toHaveLength(2)
    })

    it("filters the history by provider", async () => {
      const user = userEvent.setup()
      render(<Index {...historyProps} />)

      await user.click(
        screen.getByRole("button", { name: "Filtrar por proveedores" }),
      )
      await user.click(screen.getByLabelText("Endulzate by Noe"))
      await user.click(screen.getByRole("button", { name: "Aplicar" }))

      expect(
        screen.getByText("Endulzate by Noe: Agosto 2026"),
      ).toBeInTheDocument()
      expect(
        screen.queryByText("Tu Viandita: Julio 2026"),
      ).not.toBeInTheDocument()
      expect(screen.queryByText("Todos")).not.toBeInTheDocument()
    })

    it("says so when the chosen provider has no payments", async () => {
      const user = userEvent.setup()
      render(<Index {...historyProps} />)

      await user.click(
        screen.getByRole("button", { name: "Filtrar por proveedores" }),
      )
      await user.click(screen.getByLabelText("Sin pagos"))
      await user.click(screen.getByRole("button", { name: "Aplicar" }))

      expect(
        screen.getByText("No hay pagos de este proveedor."),
      ).toBeInTheDocument()
    })

    it("keeps the plain empty message when there are no closed periods", () => {
      render(<Index {...historyProps} history_accounts={[]} />)

      expect(
        screen.getByText("Todavía no hiciste ningún pago."),
      ).toBeInTheDocument()
      expect(screen.queryByText("Proveedores:")).not.toBeInTheDocument()
    })
const defaultProviders: PaymentProvider[] = [
  {
    id: 1,
    name: "Tu Viandita",
    bank_name: "Banco República",
    bank_account_number: "00123456",
    bank_account_holder: "Tu Viandita SRL",
    home_delivery: true,
  },
]

describe("Consumer Accounts Index Page", () => {
  it("shows the subsidized meals used this month against the monthly limit", () => {
    render(
      <Index
        accounts={[]}
        history_accounts={[]}
        providers={defaultProviders}
        history={false}
        current_month_debt={500}
        total_debt={500}
        benefit_used={3}
        benefit_available={20}
      />,
    )

    expect(screen.getByText(/3 de 20 viandas/)).toBeInTheDocument()
  })

  it("uses singular 'vianda' when the available benefit is 1", () => {
    render(
      <Index
        accounts={[]}
        history_accounts={[]}
        providers={defaultProviders}
        history={false}
        current_month_debt={0}
        total_debt={0}
        benefit_used={1}
        benefit_available={1}
      />,
    )

    expect(screen.getByText(/1 de 1 vianda/)).toBeInTheDocument()
  })

  it("displays zero meals used when no monthly benefit has been consumed", () => {
    render(
      <Index
        accounts={[]}
        history_accounts={[]}
        providers={defaultProviders}
        history={false}
        current_month_debt={0}
        total_debt={0}
        benefit_used={0}
        benefit_available={20}
      />,
    )

    expect(screen.getByText(/0 de 20 viandas/)).toBeInTheDocument()
  })
})
