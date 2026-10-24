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
  amount: 950.75,
  subsidy: 475.25,
  status: "pending",
  providers: [
    { id: 1, name: "Tu Viandita", amount: 600, status: "pending" },
    { id: 2, name: "Endulzate", amount: 350.75, status: "approved" },
  ],
  orders: [
    {
      id: 1,
      date: "14/10/2026",
      provider_id: 1,
      provider_name: "Tu Viandita",
      amount: 1,
      subsidy: 300,
      charged: 300,
    },
    {
      id: 2,
      date: "15/10/2026",
      provider_id: 1,
      provider_name: "Tu Viandita",
      amount: 1,
      subsidy: 0,
      charged: 300,
    },
    {
      id: 3,
      date: "16/10/2026",
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
    expect(screen.getByText("14/10/2026")).toBeInTheDocument()
    expect(screen.getAllByText("Tu Viandita").length).toBeGreaterThan(0)
    expect(screen.getByText("GoGrow")).toBeInTheDocument()
    expect(screen.getByText(/Total:.*950,75/)).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Cerrar" })).toBeInTheDocument()
  })

  it("abre y cancela el panel sin aplicar los cambios", async () => {
    const user = userEvent.setup()
    renderDialog()

    await user.click(screen.getByRole("button", { name: "Filtrar historial" }))
    expect(screen.getByText("Filtros del historial")).toBeInTheDocument()

    await user.click(screen.getByRole("button", { name: "Cancelar" }))
    expect(screen.queryByText("Filtros del historial")).not.toBeInTheDocument()
    expect(screen.getByText(/Total:.*950,75/)).toBeInTheDocument()
  })

  it("filtra por varios criterios y recalcula filas y totales", async () => {
    const user = userEvent.setup()
    renderDialog()

    await user.click(screen.getByRole("button", { name: "Filtrar historial" }))
    await user.click(screen.getByLabelText("Tu Viandita"))
    await user.click(screen.getByLabelText("Pendiente"))
    await user.click(screen.getByLabelText("Con subsidio aplicado"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    const table = screen.getByRole("table")
    expect(within(table).getByText("14/10/2026")).toBeInTheDocument()
    expect(within(table).queryByText("15/10/2026")).not.toBeInTheDocument()
    expect(within(table).queryByText("16/10/2026")).not.toBeInTheDocument()
    expect(screen.getByText(/Total:.*300/)).toBeInTheDocument()
    expect(screen.getByText("Proveedor: Tu Viandita")).toBeInTheDocument()
    expect(screen.getByText("Estado: Pendiente")).toBeInTheDocument()
    expect(
      screen.getByText("Subsidio: Con subsidio aplicado"),
    ).toBeInTheDocument()
  })

  it("quita un filtro individual sin perder los demás", async () => {
    const user = userEvent.setup()
    renderDialog()

    await user.click(screen.getByRole("button", { name: "Filtrar historial" }))
    await user.click(screen.getByLabelText("Tu Viandita"))
    await user.click(screen.getByLabelText("Sin subsidio aplicado"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    await user.click(
      screen.getByRole("button", {
        name: "Quitar filtro de proveedor Tu Viandita",
      }),
    )

    expect(screen.queryByText("Proveedor: Tu Viandita")).not.toBeInTheDocument()
    expect(
      screen.getByText("Subsidio: Sin subsidio aplicado"),
    ).toBeInTheDocument()
    expect(screen.getByRole("table")).toHaveTextContent("15/10/2026")
  })

  it("limpia todos los filtros y restablece el historial", async () => {
    const user = userEvent.setup()
    renderDialog()

    await user.click(screen.getByRole("button", { name: "Filtrar historial" }))
    await user.click(screen.getByLabelText("Endulzate"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))
    expect(screen.getByText(/Total:.*350,75/)).toBeInTheDocument()

    await user.click(screen.getByRole("button", { name: "Limpiar filtros" }))

    expect(screen.getByRole("table")).toHaveTextContent("14/10/2026")
    expect(screen.getByRole("table")).toHaveTextContent("16/10/2026")
    expect(screen.getByText(/Total:.*950,75/)).toBeInTheDocument()
  })

  it("explica cuando la combinación no tiene resultados y oculta totales", async () => {
    const user = userEvent.setup()
    renderDialog()

    await user.click(screen.getByRole("button", { name: "Filtrar historial" }))
    await user.click(screen.getByLabelText("Endulzate"))
    await user.click(screen.getByLabelText("Pendiente"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expect(
      screen.getByText("No hay consumos que coincidan"),
    ).toBeInTheDocument()
    expect(screen.queryByRole("table")).not.toBeInTheDocument()
    expect(screen.queryByText(/^Total:/)).not.toBeInTheDocument()
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

function renderDialog(month: AdminConsumerMonth = sampleMonth) {
  return render(
    <ConsumerMonthAdaptableDialog
      month={month}
      companyName="GoGrow"
      open={true}
      onClose={vi.fn()}
    />,
  )
}
