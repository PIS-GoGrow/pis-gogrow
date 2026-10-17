import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import SalesDetailDialog from "./sales-detail-dialog"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")

  return {
    ...actual,
    usePage: () => ({ props: { locale: "es" } }),
  }
})

const detail = {
  month: "Octubre 2026",
  clients: [
    {
      id: 1,
      name: "GoGrow",
      subtotal: 600,
      vat_amount: 66,
      payable_amount: 666,
    },
  ],
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
  it("filters the consumption detail by client", async () => {
    const user = userEvent.setup()
    render(
      <SalesDetailDialog
        detail={{
          ...detail,
          clients: [
            ...detail.clients,
            {
              id: 2,
              name: "Otra empresa",
              subtotal: 100,
              vat_amount: 11,
              payable_amount: 111,
            },
          ],
          days: [
            {
              ...detail.days[0],
              orders: [
                ...detail.days[0].orders,
                {
                  ...detail.days[0].orders[0],
                  id: 2,
                  consumer_name: "María López",
                  client_id: 2,
                  client_name: "Otra empresa",
                  amount: 100,
                },
              ],
            },
          ],
        }}
      />,
    )
    await user.click(
      screen.getByRole("button", { name: "Ver detalle del consumo" }),
    )
    expect(screen.getByText("Juan Pérez")).toBeInTheDocument()

    await user.click(
      screen.getByRole("button", { name: "Filtrar por cliente" }),
    )
    await user.click(
      screen.getByRole("menuitemradio", { name: "Otra empresa" }),
    )

    expect(screen.queryByText("Juan Pérez")).not.toBeInTheDocument()
    expect(screen.getByText("María López")).toBeInTheDocument()
    expect(screen.getByText(/Día: 09\/10/)).toHaveTextContent("100,00 UYU")
  })

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
    expect(screen.queryByText("Subtotal")).not.toBeInTheDocument()
    expect(
      screen.queryByText("IVA sobre subsidios (22 %)"),
    ).not.toBeInTheDocument()
    expect(screen.queryByText("Total")).not.toBeInTheDocument()

    await user.click(screen.getByRole("button", { name: "Cerrar" }))

    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
  })
})
