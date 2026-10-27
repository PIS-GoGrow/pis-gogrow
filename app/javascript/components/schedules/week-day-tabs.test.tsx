import "@testing-library/jest-dom/vitest"

import { cleanup, render, screen, within } from "@testing-library/react"
import { afterEach, describe, expect, it, vi } from "vitest"

import WeekDayTabs from "./week-day-tabs"

vi.mock("@inertiajs/react", () => ({ router: { get: vi.fn() } }))

afterEach(cleanup)

const day = (date: string, schedules: unknown[] = []) => ({
  date,
  publishable: true,
  schedules,
})

function renderTabs(days: ReturnType<typeof day>[]) {
  render(
    <WeekDayTabs
      days={days}
      selectedDate={days[0].date}
      onSelectDate={vi.fn()}
      previousWeekStart={null}
      nextWeekStart={null}
      today="2026-10-19"
    />,
  )
}

describe("WeekDayTabs", () => {
  it("marca como publicados solo los días con platos", () => {
    renderTabs([
      day("2026-10-19", [{ id: 1 }]),
      day("2026-10-20"),
      day("2026-10-21", [{ id: 2 }, { id: 3 }]),
      day("2026-10-22"),
      day("2026-10-23"),
    ])

    expect(screen.getAllByText("Publicado")).toHaveLength(2)

    const days = screen.getAllByRole("radio")
    expect(within(days[0]).getByText("Publicado")).toBeInTheDocument()
    expect(within(days[1]).queryByText("Publicado")).not.toBeInTheDocument()
    expect(within(days[2]).getByText("Publicado")).toBeInTheDocument()
  })

  it("deja el aviso debajo del número del día", () => {
    renderTabs([day("2026-10-19", [{ id: 1 }])])

    const [first] = screen.getAllByRole("radio")

    expect(first.textContent).toMatch(/19Publicado$/)
  })

  it("no marca ningún día cuando la semana no tiene menús", () => {
    renderTabs([day("2026-10-19"), day("2026-10-20")])

    expect(screen.queryByText("Publicado")).not.toBeInTheDocument()
  })

  it("muestra el texto publicado en verde", () => {
    renderTabs([day("2026-10-19", [{ id: 1 }])])

    const publishedBadge = screen.getByText("Publicado")
    expect(publishedBadge).toHaveClass("text-green-600", "dark:text-green-400")
  })
})
