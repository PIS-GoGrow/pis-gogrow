import "@testing-library/jest-dom/vitest"

import { cleanup, render, screen } from "@testing-library/react"
import { afterEach, describe, expect, it, vi } from "vitest"

import SavedMenusTab from "./saved-menus-tab"

afterEach(cleanup)

vi.mock("@inertiajs/react", () => ({
  router: { post: vi.fn() },
  usePage: () => ({ props: { locale: "es" } }),
}))

describe("SavedMenusTab", () => {
  const menus = [
    {
      id: 1,
      name: "Bowl de lentejas",
      description: "Opción vegetariana",
      price: 280,
      confirmed_orders: 0,
      pending_orders: 0,
      // Se repite todos los viernes
      weekdays: [5],
    },
  ]

  function renderTab(date: string) {
    render(
      <SavedMenusTab
        menus={menus}
        // 2030-01-07 es lunes
        published={[
          { date: "2030-01-07", menu_id: 1 },
          { date: "2030-01-09", menu_id: 1 },
          { date: "2030-01-14", menu_id: 1 },
          { date: "2030-01-08", menu_id: 2 },
        ]}
        today="2030-01-07"
        maximumPublishDate="2030-01-18"
        onPublished={vi.fn()}
        defaultDate={date}
      />,
    )
  }

  it("marca los días que se repiten y los publicados esa semana sin repetición", () => {
    renderTab("2030-01-10")

    expect(screen.getByText("Lunes, Miércoles, Viernes")).toBeInTheDocument()
  })

  it("cambia los días sueltos según la semana de la fecha elegida", () => {
    renderTab("2030-01-15")

    expect(screen.getByText("Lunes, Viernes")).toBeInTheDocument()
  })
})
