import { render, screen, within } from "@testing-library/react"
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
  name: "Octubre",
  amount: 950.75,
  subsidy: 475.25,
  status: "pending",
  providers: [
    {
      id: 1,
      name: "Tu Viandita",
      amount: 600,
      status: "pending",
      receipt_url: null,
    },
    {
      id: 2,
      name: "Endulzate",
      amount: 350.75,
      status: "approved",
      receipt_url: "/rrhh/pagos/9/archivo",
    },
  ],
  orders: [
    {
      id: 1,
      date: "14/10",
      provider_id: 1,
      provider_name: "Tu Viandita",
      amount: 1,
      subsidy: 300,
      charged: 300,
    },
    {
      id: 2,
      date: "15/10",
      provider_id: 1,
      provider_name: "Tu Viandita",
      amount: 1,
      subsidy: 0,
      charged: 300,
    },
    {
      id: 3,
      date: "16/10",
      provider_id: 2,
      provider_name: "Endulzate",
      amount: 1,
      subsidy: 175.25,
      charged: 350.75,
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
    expect(screen.getByText("14/10")).toBeInTheDocument()
    expect(screen.getAllByText("Tu Viandita").length).toBeGreaterThan(0)
    expect(screen.getByText("GoGrow")).toBeInTheDocument()
    expect(screen.getByText(/Total:.*950,75/)).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Cerrar" })).toBeInTheDocument()
  })

  it("shows each provider balance with its status and the receipt to download", () => {
    render(
      <ConsumerMonthAdaptableDialog
        month={sampleMonth}
        companyName="GoGrow"
        open={true}
        onClose={vi.fn()}
      />,
    )

    expect(screen.getByText(/Endulzate: \$350,75/)).toBeInTheDocument()
    expect(screen.getByText("Confirmado")).toBeInTheDocument()
    expect(screen.getByText("Pendiente")).toBeInTheDocument()
    expect(
      screen.getByRole("link", {
        name: "Descargar el comprobante de Endulzate",
      }),
    ).toHaveAttribute("href", "/rrhh/pagos/9/archivo")
    expect(
      screen.queryByRole("link", {
        name: "Descargar el comprobante de Tu Viandita",
      }),
    ).not.toBeInTheDocument()
  })

  it("switches between every provider and a single one", async () => {
    const user = userEvent.setup()
    render(
      <ConsumerMonthAdaptableDialog
        month={sampleMonth}
        companyName="GoGrow"
        open={true}
        onClose={vi.fn()}
      />,
    )

    expect(screen.getByText("Proveedores:")).toHaveTextContent("Todos")

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedor" }),
    )
    await user.click(screen.getByRole("menuitemradio", { name: "Endulzate" }))

    const table = screen.getByRole("table")
    expect(within(table).getAllByRole("row")).toHaveLength(2)
    expect(within(table).getByText("16/10")).toBeInTheDocument()
    expect(screen.getByText(/Total:.*350,75/)).toBeInTheDocument()

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedor" }),
    )
    await user.click(screen.getByRole("menuitemradio", { name: "Todos" }))

    expect(within(screen.getByRole("table")).getAllByRole("row")).toHaveLength(
      4,
    )
  })
})
