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
    expect(draftFromNone.amount).toBe("")

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
    expect(draftFromWeekly.amount).toBe("10")
  })

  it("returns mode none in agendaPayload when weekdays is empty", () => {
    const draft: AgendaDraft = {
      mode: "weekly",
      weekdays: [],
      date: "",
      starts_on: "2030-01-09",
      ends_on: "",
      amount: "5",
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
      amount: "8",
    }

    expect(agendaPayload(draft)).toEqual(draft)
  })
})

describe("MenuAgendaFields component", () => {
  const defaultDraft: AgendaDraft = {
    mode: "single",
    weekdays: [3],
    date: "2030-01-09",
    starts_on: "",
    ends_on: "",
    amount: "15",
  }

  it("renders stock input and calls onChange when edited", async () => {
    const user = userEvent.setup()
    const onChange = vi.fn()

    render(
      <MenuAgendaFields
        value={defaultDraft}
        onChange={onChange}
        today="2030-01-09"
        maximumPublishDate="2030-01-18"
      />,
    )

    const amountInput = screen.getByDisplayValue("15")
    expect(amountInput).toBeInTheDocument()

    await user.clear(amountInput)
    await user.type(amountInput, "20")

    expect(onChange).toHaveBeenCalled()
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
})
