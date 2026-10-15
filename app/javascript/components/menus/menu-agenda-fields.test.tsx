import "@testing-library/jest-dom/vitest"

import { cleanup, render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, describe, expect, it, vi } from "vitest"

import MenuAgendaFields, {
  type AgendaDraft,
  agendaPayload,
  cwday,
  initialAgenda,
} from "./menu-agenda-fields"

afterEach(cleanup)

describe("MenuAgendaFields helpers", () => {
  it("computes ISO day of week correctly with cwday", () => {
    // 2030-01-09 is Wednesday (3)
    expect(cwday("2030-01-09")).toBe(3)
    // 2030-01-13 is Sunday (7)
    expect(cwday("2030-01-13")).toBe(7)
  })

  it("converts initial agenda into draft with defaults", () => {
    const draftFromNone = initialAgenda({
      mode: "none",
      weekdays: [],
      date: null,
      starts_on: null,
      ends_on: null,
      amount: null,
    })

    expect(draftFromNone.mode).toBe("single")
    expect(draftFromNone.weekdays).toEqual([])

    const draftFromWeekly = initialAgenda({
      mode: "weekly",
      weekdays: [1, 5],
      date: null,
      starts_on: "2030-01-09",
      ends_on: null,
      amount: 10,
    })

    expect(draftFromWeekly.mode).toBe("weekly")
    expect(draftFromWeekly.weekdays).toEqual([1, 5])
    expect(draftFromWeekly).not.toHaveProperty("amount")
  })

  it("returns mode none in agendaPayload when weekdays is empty", () => {
    const draft: AgendaDraft = {
      mode: "weekly",
      weekdays: [],
      date: "",
      starts_on: "2030-01-09",
      ends_on: "",
    }

    expect(agendaPayload(draft)).toEqual({ mode: "none" })
  })

  it("returns full draft in agendaPayload when weekdays has days", () => {
    const draft: AgendaDraft = {
      mode: "range",
      weekdays: [2, 4],
      date: "",
      starts_on: "2030-01-10",
      ends_on: "2030-01-15",
    }

    expect(agendaPayload(draft)).toEqual(draft)
  })

  it("returns full weekly draft in agendaPayload when weekly mode is configured", () => {
    const weeklyDraft: AgendaDraft = {
      mode: "weekly",
      weekdays: [1, 3, 5],
      date: "",
      starts_on: "2030-01-09",
      ends_on: "",
    }

    expect(agendaPayload(weeklyDraft)).toEqual(weeklyDraft)
  })
})

describe("MenuAgendaFields component", () => {
  const defaultDraft: AgendaDraft = {
    mode: "single",
    weekdays: [3],
    date: "2030-01-09",
    starts_on: "",
    ends_on: "",
  }

  it("does not render a stock input", () => {
    render(
      <MenuAgendaFields
        value={defaultDraft}
        onChange={vi.fn()}
        today="2030-01-09"
        maximumPublishDate="2030-01-18"
      />,
    )

    expect(screen.queryByRole("spinbutton")).not.toBeInTheDocument()
  })

  it("renders separate from and to pickers for a custom range", () => {
    render(
      <MenuAgendaFields
        value={{
          ...defaultDraft,
          mode: "range",
          starts_on: "2030-01-10",
          ends_on: "2030-01-15",
        }}
        onChange={vi.fn()}
        today="2030-01-09"
        maximumPublishDate="2030-01-18"
      />,
    )

    expect(screen.getByLabelText("Desde")).toHaveTextContent("Enero 10, 2030")
    expect(screen.getByLabelText("Hasta")).toHaveTextContent("Enero 15, 2030")
  })

  it("renders error message when error prop is provided", () => {
    const errorMessage = "Elegí al menos un día de lunes a viernes."

    render(
      <MenuAgendaFields
        value={defaultDraft}
        onChange={vi.fn()}
        today="2030-01-09"
        maximumPublishDate="2030-01-18"
        error={errorMessage}
      />,
    )

    expect(screen.getByText(errorMessage)).toBeInTheDocument()
  })

  it("renders weekly mode radio and allows switching mode", async () => {
    const user = userEvent.setup()
    const onChange = vi.fn()

    const weeklyDraft: AgendaDraft = {
      mode: "weekly",
      weekdays: [2, 4],
      date: "",
      starts_on: "2030-01-09",
      ends_on: "",
    }

    render(
      <MenuAgendaFields
        value={weeklyDraft}
        onChange={onChange}
        today="2030-01-09"
        maximumPublishDate="2030-01-18"
      />,
    )

    const weeklyRadio = screen.getByLabelText(/repetir todas las semanas/i)
    expect(weeklyRadio).toBeChecked()

    const singleRadio = screen.getByLabelText(/no repetir/i)
    await user.click(singleRadio)

    expect(onChange).toHaveBeenCalledWith(
      expect.objectContaining({
        mode: "single",
      }),
    )
  })
})
