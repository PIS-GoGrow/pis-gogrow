import "@testing-library/jest-dom/vitest"

import { cleanup, fireEvent, render, screen } from "@testing-library/react"
import { afterEach, describe, expect, it, vi } from "vitest"

import SavedMenusTab from "./saved-menus-tab"

afterEach(cleanup)

const post = vi.hoisted(() => vi.fn())

vi.mock("@inertiajs/react", () => ({
  router: { post },
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
    {
      id: 2,
      name: "Ensalada completa",
      description: "Opción fresca",
      price: 250,
      confirmed_orders: 0,
      pending_orders: 0,
      weekdays: [2],
    },
  ]

  function renderTab(date: string, onPublished = vi.fn()) {
    render(
      <SavedMenusTab
        menus={menus}
        published={[
          { date: "2030-01-07", menu_id: 1 },
          { date: "2030-01-09", menu_id: 1 },
          { date: "2030-01-14", menu_id: 1 },
          { date: "2030-01-08", menu_id: 2 },
        ]}
        today="2030-01-07"
        maximumPublishDate="2030-01-18"
        onPublished={onPublished}
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

  it("informa cuántos platos fueron publicados", () => {
    const onPublished = vi.fn()

    renderTab("2030-01-10", onPublished)

    fireEvent.click(
      screen.getByRole("button", {
        name: "Agregar Bowl de lentejas a la selección",
      }),
    )
    fireEvent.click(
      screen.getByRole("button", {
        name: "Agregar Ensalada completa a la selección",
      }),
    )

    fireEvent.click(screen.getByRole("button", { name: "Agregar" }))

    expect(post).toHaveBeenCalledTimes(1)

    const options = post.mock.calls[0][2] as {
      onSuccess: () => void
    }

    options.onSuccess()

    expect(onPublished).toHaveBeenCalledWith("2030-01-10", 2)
  })
})
