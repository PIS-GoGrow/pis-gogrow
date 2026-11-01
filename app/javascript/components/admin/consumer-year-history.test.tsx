import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeAll, describe, expect, it, vi } from "vitest"

import type { AdminConsumerMonth } from "@/types"

import ConsumerYearHistory from "./consumer-year-history"

vi.mock("@/hooks/use-formatters", () => ({
  useFormatters: () => ({
    formatMoney: (amount: number) => `$${amount}`,
  }),
}))

vi.mock("@/components/admin/consumer-month-sheet", () => ({
  default: ({ month, open }: { month?: AdminConsumerMonth; open: boolean }) =>
    open && month ? <div data-testid="month-sheet">{month.label}</div> : null,
}))

beforeAll(() => {
  Object.defineProperties(Element.prototype, {
    hasPointerCapture: { configurable: true, value: () => false },
    setPointerCapture: { configurable: true, value: () => undefined },
    releasePointerCapture: { configurable: true, value: () => undefined },
    scrollIntoView: { configurable: true, value: () => undefined },
  })
})

const order: AdminConsumerMonth["orders"][number] = {
  id: 1,
  date: "14/10",
  provider_id: 1,
  provider_name: "Tu Viandita",
  amount: 1,
  subsidy: 150,
  charged: 150,
}

function month(
  key: string,
  name: string,
  amount = 0,
  status: AdminConsumerMonth["status"] = null,
): AdminConsumerMonth {
  return {
    key,
    year: Number(key.slice(0, 4)),
    amount,
    subsidy: 0,
    label: `${name} ${key.slice(0, 4)}`,
    name,
    status,
    providers: [],
    orders: amount > 0 ? [order] : [],
  }
}

describe("ConsumerYearHistory", () => {
  it("lists every month of the year once the employee ordered, with the empty ones as Sin consumos", () => {
    render(
      <ConsumerYearHistory
        companyName="GoGrow"
        months={[
          month("2026-12", "Diciembre"),
          month("2026-01", "Enero", 150, "approved"),
        ]}
      />,
    )

    expect(screen.getByRole("combobox", { name: "Año" })).toHaveTextContent(
      "2026",
    )
    expect(
      screen.getAllByRole("button", { name: /Ver el detalle/ }),
    ).toHaveLength(2)
    expect(screen.getByText("Diciembre")).toBeInTheDocument()
    expect(screen.getByText("Sin consumos")).toBeInTheDocument()
    expect(screen.getByText("Confirmado")).toBeInTheDocument()
  })

  it("shows the empty state when the employee never ordered", () => {
    render(
      <ConsumerYearHistory
        companyName="GoGrow"
        months={[month("2026-12", "Diciembre"), month("2026-11", "Noviembre")]}
      />,
    )

    expect(
      screen.getByText(
        "Este empleado todavía no realizó ningún pedido de viandas.",
      ),
    ).toBeInTheDocument()
    expect(screen.queryByRole("combobox")).not.toBeInTheDocument()
    expect(
      screen.queryByRole("button", { name: /Ver el detalle/ }),
    ).not.toBeInTheDocument()
  })

  it("shows only the months of the selected year", async () => {
    const user = userEvent.setup()
    render(
      <ConsumerYearHistory
        companyName="GoGrow"
        months={[
          month("2026-12", "Diciembre"),
          month("2025-11", "Noviembre", 150, "approved"),
        ]}
      />,
    )

    expect(screen.getByText("Diciembre")).toBeInTheDocument()
    expect(screen.queryByText("Noviembre")).not.toBeInTheDocument()

    await user.click(screen.getByRole("combobox", { name: "Año" }))
    await user.click(screen.getByRole("option", { name: "2025" }))

    expect(screen.queryByText("Diciembre")).not.toBeInTheDocument()
    expect(screen.getByText("Noviembre")).toBeInTheDocument()
    expect(screen.getByText("$150")).toBeInTheDocument()
  })

  it("keeps the existing navigation to the selected month detail", async () => {
    const user = userEvent.setup()
    render(
      <ConsumerYearHistory
        companyName="GoGrow"
        months={[month("2026-10", "Octubre", 290, "pending")]}
      />,
    )

    await user.click(
      screen.getByRole("button", {
        name: "Ver el detalle de Octubre 2026",
      }),
    )

    expect(screen.getByTestId("month-sheet")).toHaveTextContent("Octubre 2026")
  })
})
