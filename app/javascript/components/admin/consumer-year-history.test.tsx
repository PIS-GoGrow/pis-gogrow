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

function month(
  key: string,
  label: string,
  amount = 0,
  status: AdminConsumerMonth["status"] = null,
): AdminConsumerMonth {
  return {
    key,
    year: Number(key.slice(0, 4)),
    amount,
    subsidy: 0,
    label,
    status,
    providers: [],
    orders: [],
  }
}

describe("ConsumerYearHistory", () => {
  it("shows the year selector even when only the current year is available", () => {
    render(
      <ConsumerYearHistory
        companyName="GoGrow"
        months={[
          month("2026-12", "Diciembre 2026"),
          month("2026-01", "Enero 2026"),
        ]}
      />,
    )

    expect(screen.getByRole("combobox", { name: "Año" })).toHaveTextContent(
      "2026",
    )
    expect(
      screen.getAllByRole("button", { name: /Ver el detalle/ }),
    ).toHaveLength(2)
    expect(screen.getAllByText("$0")).toHaveLength(2)
    expect(screen.getAllByText("Sin consumos")).toHaveLength(2)
  })

  it("shows only the months of the selected year", async () => {
    const user = userEvent.setup()
    render(
      <ConsumerYearHistory
        companyName="GoGrow"
        months={[
          month("2026-12", "Diciembre 2026"),
          month("2025-11", "Noviembre 2025", 150, "approved"),
        ]}
      />,
    )

    expect(screen.getByText("Diciembre 2026")).toBeInTheDocument()
    expect(screen.queryByText("Noviembre 2025")).not.toBeInTheDocument()

    await user.click(screen.getByRole("combobox", { name: "Año" }))
    await user.click(screen.getByRole("option", { name: "2025" }))

    expect(screen.queryByText("Diciembre 2026")).not.toBeInTheDocument()
    expect(screen.getByText("Noviembre 2025")).toBeInTheDocument()
    expect(screen.getByText("$150")).toBeInTheDocument()
    expect(screen.getByText("Aprobado")).toBeInTheDocument()
  })

  it("keeps the existing navigation to the selected month detail", async () => {
    const user = userEvent.setup()
    render(
      <ConsumerYearHistory
        companyName="GoGrow"
        months={[month("2026-10", "Octubre 2026", 290, "pending")]}
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
