import { render, screen } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

import MonthSelect from "./month-select"

const sampleMonths = [
  { key: "2026-10", label: "octubre 2026" },
  { key: "2026-09", label: "septiembre 2026" },
  { key: "2026-08", label: "agosto 2026" },
]

describe("MonthSelect component", () => {
  it("renders the trigger with the specified aria-label", () => {
    render(
      <MonthSelect
        value="2026-10"
        currentMonth="2026-10"
        months={sampleMonths}
        onValueChange={vi.fn()}
        label="Mes de los saldos"
      />,
    )

    expect(
      screen.getByRole("combobox", { name: "Mes de los saldos" }),
    ).toBeInTheDocument()
  })

  it("displays 'Este mes' when the current month is selected", () => {
    render(
      <MonthSelect
        value="2026-10"
        currentMonth="2026-10"
        months={sampleMonths}
        onValueChange={vi.fn()}
        label="Mes de los saldos"
      />,
    )

    expect(
      screen.getByRole("combobox", { name: "Mes de los saldos" }),
    ).toHaveTextContent("Este mes")
  })

  it("displays the month label when a past month is selected", () => {
    render(
      <MonthSelect
        value="2026-09"
        currentMonth="2026-10"
        months={sampleMonths}
        onValueChange={vi.fn()}
        label="Mes de los saldos"
      />,
    )

    expect(
      screen.getByRole("combobox", { name: "Mes de los saldos" }),
    ).toHaveTextContent("septiembre 2026")
  })
})
