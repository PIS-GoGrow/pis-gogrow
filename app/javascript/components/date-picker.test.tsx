import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import { DatePicker, DateRangePicker } from "./date-picker"

// Figma "Date Picker": el botón muestra "09/06/27 – 27/06/27".
function renderRange(from: string, to: string) {
  render(<DateRangePicker id="range" from={from} to={to} onChange={vi.fn()} />)
  return screen.getByRole("button")
}

describe("DateRangePicker", () => {
  it("asks for a range while there are no dates", () => {
    expect(renderRange("", "")).toHaveTextContent("Elegí un rango")
  })

  it("writes the year once for a range inside a year", () => {
    expect(renderRange("2027-06-09", "2027-06-27")).toHaveTextContent(
      "09/06/27 – 27/06/27",
    )
  })

  it("writes both years when the range crosses a year", () => {
    expect(renderRange("2026-12-28", "2027-01-03")).toHaveTextContent(
      "28/12/26 – 03/01/27",
    )
  })

  it("writes just the start while the end is not chosen yet", () => {
    expect(renderRange("2027-06-09", "")).toHaveTextContent("09/06/27")
  })

  it("opens a calendar that starts on Sunday with the English header of the Figma", async () => {
    const user = userEvent.setup()
    renderRange("2027-06-09", "2027-06-27")

    await user.click(screen.getByRole("button"))

    expect(
      screen
        .getAllByText(/^(Su|Mo|Tu|We|Th|Fr|Sa)$/)
        .map((header) => header.textContent),
    ).toEqual(["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"])
    expect(screen.getAllByText("Jun").length).toBeGreaterThan(0)
  })

  it("writes a single day once", () => {
    const button = renderRange("2027-06-09", "2027-06-09")

    expect(button).toHaveTextContent("09/06/27")
    expect(button).not.toHaveTextContent("–")
  })
})

describe("DatePicker", () => {
  it("keeps the selected calendar day as ISO while displaying the unified date", async () => {
    const user = userEvent.setup()
    const onChange = vi.fn()
    render(<DatePicker value="2026-10-25" onChange={onChange} />)

    expect(screen.getByRole("button")).toHaveTextContent(
      "Domingo 25 de octubre",
    )
    await user.click(screen.getByRole("button"))
    await user.click(
      screen.getByRole("button", { name: / 28 de octubre de 2026/ }),
    )

    expect(onChange).toHaveBeenCalledExactlyOnceWith("2026-10-28")
  })
})
