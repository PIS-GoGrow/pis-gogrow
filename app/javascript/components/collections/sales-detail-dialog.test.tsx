import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import SalesDetailDialog from "./sales-detail-dialog"

vi.mock("@inertiajs/react", async () => {
  const actual =
    await vi.importActual<typeof import("@inertiajs/react")>("@inertiajs/react")

  return {
    ...actual,
    usePage: () => ({ props: { locale: "es" } }),
  }
})

const detail = {
  month: "Octubre 2026",
  clients: [{ id: 1, name: "GoGrow" }],
  days: [
    {
      date: "09/10",
      orders: [
        {
          id: 1,
          consumer_name: "Juan Pérez",
          client_id: 1,
          client_name: "GoGrow",
          meals: 2,
          amount: 600,
        },
      ],
    },
  ],
}

describe("SalesDetailDialog", () => {
  it("opens the monthly detail and shows confirmed orders by day", async () => {
    const user = userEvent.setup()
    render(<SalesDetailDialog detail={detail} />)

    await user.click(
      screen.getByRole("button", { name: "Ver detalle del consumo" }),
    )

    expect(
      screen.getByText("Detalle de consumo: Octubre 2026"),
    ).toBeInTheDocument()
    expect(screen.getByText("GoGrow")).toBeInTheDocument()
    expect(screen.getByText("Juan Pérez")).toBeInTheDocument()
    expect(screen.getByText(/Día: 09\/10/)).toHaveTextContent("Viandas: 2")
    expect(screen.getByText(/Día: 09\/10/)).toHaveTextContent("600,00 UYU")

    await user.click(screen.getByRole("button", { name: "Cerrar" }))

    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
  })
})
