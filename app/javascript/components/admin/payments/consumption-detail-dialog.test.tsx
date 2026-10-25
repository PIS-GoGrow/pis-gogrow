import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { useState } from "react"
import { describe, expect, it, vi } from "vitest"

import ConsumptionDetailDialog, {
  type ConsumptionDetail,
} from "./consumption-detail-dialog"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")

  return {
    ...actual,
    usePage: () => ({ props: { locale: "es" } }),
  }
})

const tuViandita: ConsumptionDetail["providers"][number] = {
  id: 2,
  name: "Tu Viandita",
  meals: 108,
  subtotal: 16200,
  vat_rate: 22,
  vat_amount: 3564,
  payable_amount: 19764,
  paid: true,
  days: [
    {
      date: "30/08",
      orders: [
        {
          id: 1,
          consumer_name: "Bruno Pérez",
          avatar_url: null,
          meals: 1,
          employee_amount: 130,
          company_amount: 170,
        },
        {
          id: 2,
          consumer_name: "Camila Herrera",
          avatar_url: null,
          meals: 2,
          employee_amount: 300,
          company_amount: 300,
        },
      ],
    },
  ],
}

const endulzate: ConsumptionDetail["providers"][number] = {
  ...tuViandita,
  id: 1,
  name: "Endulzate by Noe",
  meals: 30,
  subtotal: 4500,
  days: [],
}

function Harness({
  providers,
  initialProviderId = null,
}: {
  providers: ConsumptionDetail["providers"]
  initialProviderId?: number | null
}) {
  const [providerId, setProviderId] = useState(initialProviderId)

  return (
    <ConsumptionDetailDialog
      detail={{ month: "Agosto 2026", providers }}
      providerId={providerId}
      onProviderChange={setProviderId}
      loading={false}
      open
      onOpenChange={vi.fn()}
    />
  )
}

describe("ConsumptionDetailDialog", () => {
  it("muestra el pago del proveedor como en el diseño", () => {
    render(<Harness providers={[tuViandita]} />)

    const dialog = screen.getByRole("dialog")
    expect(dialog).toHaveTextContent("Tu Viandita: Consumo Agosto 2026")
    expect(dialog).toHaveTextContent("Subtotal sin IVA$16.200 | 108 viandas")
    expect(dialog).toHaveTextContent("IVA (22%)$3.564")
    expect(dialog).toHaveTextContent("Total pagado$19.764")
    expect(screen.getByRole("button", { name: "Cerrar" })).toBeInTheDocument()
  })

  // IBP-032 CA3: el detalle no puede llamar "pagado" a lo que la tarjeta muestra
  // como pendiente.
  it("rotula el total como a pagar mientras el pago no está aprobado", () => {
    render(<Harness providers={[{ ...tuViandita, paid: false }]} />)

    const dialog = screen.getByRole("dialog")
    expect(dialog).toHaveTextContent("Total a pagar$19.764")
    expect(dialog).not.toHaveTextContent("Total pagado")
  })

  it("no muestra el filtro si el mes tiene un solo proveedor", () => {
    render(<Harness providers={[tuViandita]} />)

    expect(
      screen.queryByRole("button", { name: "Filtrar por proveedor" }),
    ).not.toBeInTheDocument()
  })

  it("abre el proveedor elegido y deja cambiarlo desde el filtro", async () => {
    const user = userEvent.setup()
    render(
      <Harness providers={[endulzate, tuViandita]} initialProviderId={2} />,
    )

    expect(screen.getByRole("dialog")).toHaveTextContent(
      "Tu Viandita: Consumo Agosto 2026",
    )

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedor" }),
    )
    await user.click(
      screen.getByRole("menuitemradio", { name: "Endulzate by Noe" }),
    )

    expect(screen.getByRole("dialog")).toHaveTextContent(
      "Endulzate by Noe: Consumo Agosto 2026",
    )
    expect(screen.getByRole("dialog")).toHaveTextContent("$4.500 | 30 viandas")
  })

  it("abre el primer proveedor si no se eligió ninguno", () => {
    render(<Harness providers={[endulzate, tuViandita]} />)

    expect(screen.getByRole("dialog")).toHaveTextContent(
      "Endulzate by Noe: Consumo Agosto 2026",
    )
  })

  it("lista las viandas de cada día con lo que paga el empleado y GoGrow", async () => {
    const user = userEvent.setup()
    render(<Harness providers={[tuViandita]} />)

    await user.click(screen.getByRole("tab", { name: "Viandas" }))

    expect(
      screen.getByRole("button", {
        name: "Día: 30/08 | Viandas: 3 | Monto: $470",
      }),
    ).toBeInTheDocument()

    const table = screen.getByRole("table")
    expect(
      within(table)
        .getAllByRole("columnheader")
        .map((header) => header.textContent),
    ).toEqual(["Usuario", "Cant.", "Empleado", "GoGrow"])
    expect(
      within(table).getByRole("row", { name: /Bruno Pérez/ }),
    ).toHaveTextContent("1$130$170")
  })
})
