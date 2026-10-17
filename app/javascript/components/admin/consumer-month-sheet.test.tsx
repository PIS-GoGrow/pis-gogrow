import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import type { AdminConsumerMonth } from "@/types"

import ConsumerMonthAdaptableDialog from "./consumer-month-sheet"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    usePage: () => ({ props: { locale: "es" } }),
  }
})

const sampleMonth: AdminConsumerMonth = {
  key: "2026-10",
  year: 2026,
  label: "Octubre 2026",
  amount: 950.75,
  subsidy: 475.25,
  status: "pending",
  providers: [
    { name: "Tu Viandita", amount: 600, status: "pending" },
    { name: "Endulzate", amount: 350.75, status: "approved" },
  ],
  orders: [
    {
      id: 1,
      date: "14/10/2026",
      provider_name: "Tu Viandita",
      amount: 2,
      subsidy: 300,
      charged: 300,
    },
  ],
}

describe("ConsumerMonthAdaptableDialog", () => {
  it("renders the month title, orders table and provider balances when open", () => {
    render(
      <ConsumerMonthAdaptableDialog
        month={sampleMonth}
        companyName="GoGrow"
        open={true}
        onClose={vi.fn()}
      />,
    )

    expect(
      screen.getByText("Historial de consumo: Octubre 2026"),
    ).toBeInTheDocument()
    expect(screen.getByText("14/10/2026")).toBeInTheDocument()
    expect(screen.getByText("Tu Viandita")).toBeInTheDocument()
    expect(screen.getByText("GoGrow")).toBeInTheDocument()
    expect(screen.getByText(/Total:.*950,75/)).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Cerrar" })).toBeInTheDocument()
  })

  it("shows an empty message when there are no orders in the month", () => {
    const emptyMonth: AdminConsumerMonth = {
      ...sampleMonth,
      orders: [],
    }

    render(
      <ConsumerMonthAdaptableDialog
        month={emptyMonth}
        companyName="GoGrow"
        open={true}
        onClose={vi.fn()}
      />,
    )

    expect(
      screen.getByText("No hay pedidos confirmados en este mes."),
    ).toBeInTheDocument()
  })

  it("triggers onClose when clicking the close button", async () => {
    const user = userEvent.setup()
    const handleClose = vi.fn()

    render(
      <ConsumerMonthAdaptableDialog
        month={sampleMonth}
        companyName="GoGrow"
        open={true}
        onClose={handleClose}
      />,
    )

    await user.click(screen.getByRole("button", { name: "Cerrar" }))
    expect(handleClose).toHaveBeenCalled()
  })
})
