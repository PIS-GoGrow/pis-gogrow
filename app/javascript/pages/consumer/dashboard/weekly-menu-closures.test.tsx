import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { useState } from "react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import type { ConsumerClosure } from "@/types"

import type { Schedule } from "./consumer-types"
import { WeeklyMenu } from "./weekly-menu"

type MenuProps = Omit<
  Parameters<typeof WeeklyMenu>[0],
  "activeProviders" | "setActiveProviders"
>

function ControlledWeeklyMenu(props: MenuProps) {
  const [activeProviders, setActiveProviders] = useState<Set<number>>(new Set())

  return (
    <WeeklyMenu
      {...props}
      activeProviders={activeProviders}
      setActiveProviders={setActiveProviders}
    />
  )
}

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")

  return {
    ...actual,
    usePage: () => ({ url: "/menu-semanal", props: { notifications: [] } }),
  }
})

// IBP-087: el proveedor programó un cierre. El empleado no ve sus platos del
// día cerrado (el servidor ya los saca), y sabe por qué.
const monday = "2026-09-14"

const schedule: Schedule = {
  id: 1,
  date: monday,
  remaining: 5,
  sold_out: false,
  orders_closed: false,
  menu: {
    id: 10,
    name: "Wok de verduras + arroz",
    description: "Salteado al wok",
    price: 140,
    provider_id: 2,
    option_groups: [],
    provider_name: "Endulzate by Noe",
    home_delivery: true,
    rating_average: null,
    rating_count: 0,
    reviews: [],
  },
}

const closure = (
  overrides: Partial<ConsumerClosure> = {},
): ConsumerClosure => ({
  id: 1,
  provider_id: 1,
  provider_name: "Tu Viandita",
  reason: "Vacaciones",
  starts_on: "2027-06-09",
  ends_on: "2027-06-27",
  period: "09/06/27 al 27/06/27",
  ...overrides,
})

function renderMenu(props: Partial<MenuProps> = {}, date = monday) {
  return render(
    <ControlledWeeklyMenu
      name="Sofía"
      date={date}
      setDate={vi.fn()}
      benefit={{
        percentage: 50,
        monthly_limit: 20,
        monthly_used: 2,
        monthly_remaining: 18,
        specials: [],
      }}
      providers={[
        { id: 2, name: "Endulzate by Noe", order_deadline: null },
        { id: 1, name: "Tu Viandita", order_deadline: null },
      ]}
      schedules={[schedule]}
      closures={[]}
      cart={[]}
      count={0}
      total={0}
      loading={false}
      openDetail={vi.fn()}
      {...props}
    />,
  )
}

describe("WeeklyMenu closures", () => {
  beforeEach(() => {
    window.sessionStorage.clear()
  })

  it("shows no notice when nobody closed", () => {
    renderMenu()

    expect(screen.queryByText(/no estará disponible/)).not.toBeInTheDocument()
    expect(screen.queryByText(/no está disponible/)).not.toBeInTheDocument()
    expect(screen.getByText("Wok de verduras + arroz")).toBeInTheDocument()
  })

  it("warns ahead of a closure that starts later, with the reason", () => {
    renderMenu({ closures: [closure()] })

    expect(
      screen.getByText("Tu Viandita no estará disponible"),
    ).toBeInTheDocument()
    expect(
      screen.getByText(
        "Sus viandas no estarán disponibles del 09/06/27 al 27/06/27. Motivo: Vacaciones",
      ),
    ).toBeInTheDocument()
    expect(screen.getByText("Wok de verduras + arroz")).toBeInTheDocument()
  })

  it("lets the employee dismiss the notice and keeps it dismissed", async () => {
    const user = userEvent.setup()
    const { unmount } = renderMenu({ closures: [closure()] })

    await user.click(screen.getByRole("button", { name: "Cerrar aviso" }))
    expect(
      screen.queryByText("Tu Viandita no estará disponible"),
    ).not.toBeInTheDocument()

    unmount()
    renderMenu({ closures: [closure()] })

    expect(
      screen.queryByText("Tu Viandita no estará disponible"),
    ).not.toBeInTheDocument()
  })

  it("says the provider is not available while the selected day is inside the closure", () => {
    renderMenu(
      {
        closures: [
          closure({
            starts_on: "2026-09-10",
            ends_on: "2026-09-18",
            period: "10/09/26 al 18/09/26",
          }),
        ],
      },
      monday,
    )

    expect(
      screen.getByText("Tu Viandita no está disponible"),
    ).toBeInTheDocument()
    expect(
      screen.queryByText("Tu Viandita no estará disponible"),
    ).not.toBeInTheDocument()
    expect(screen.getByText("Wok de verduras + arroz")).toBeInTheDocument()
  })

  it("lets the employee dismiss the notice shown inside the closure", async () => {
    const user = userEvent.setup()
    const inside = closure({
      starts_on: "2026-09-10",
      ends_on: "2026-09-18",
      period: "10/09/26 al 18/09/26",
    })
    const { unmount } = renderMenu({ closures: [inside] })

    await user.click(screen.getByRole("button", { name: "Cerrar aviso" }))
    expect(
      screen.queryByText("Tu Viandita no está disponible"),
    ).not.toBeInTheDocument()

    unmount()
    renderMenu({ closures: [inside] })

    expect(
      screen.queryByText("Tu Viandita no está disponible"),
    ).not.toBeInTheDocument()
  })

  // El aviso de antes del cierre y el de durante son independientes.
  it("keeps the notice inside the closure after dismissing the one ahead of it", async () => {
    const user = userEvent.setup()
    const midweek = closure({ starts_on: "2026-09-16", ends_on: "2026-09-18" })
    const { unmount } = renderMenu({ closures: [midweek] }, "2026-09-14")

    await user.click(screen.getByRole("button", { name: "Cerrar aviso" }))
    unmount()
    renderMenu({ closures: [midweek] }, "2026-09-16")

    expect(
      screen.getByText("Tu Viandita no está disponible"),
    ).toBeInTheDocument()
  })

  it("keeps the notice ahead of the closure after dismissing the one inside it", async () => {
    const user = userEvent.setup()
    const midweek = closure({ starts_on: "2026-09-16", ends_on: "2026-09-18" })
    const { unmount } = renderMenu({ closures: [midweek] }, "2026-09-16")

    await user.click(screen.getByRole("button", { name: "Cerrar aviso" }))
    unmount()
    renderMenu({ closures: [midweek] }, "2026-09-14")

    expect(
      screen.getByText("Tu Viandita no estará disponible"),
    ).toBeInTheDocument()
  })

  it("keeps explaining the closure after its notice was dismissed", async () => {
    const user = userEvent.setup()
    renderMenu({
      schedules: [],
      closures: [
        closure({
          starts_on: "2026-09-10",
          ends_on: "2026-09-18",
          period: "10/09/26 al 18/09/26",
        }),
      ],
    })

    await user.click(screen.getByRole("button", { name: "Cerrar aviso" }))
    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Endulzate by Noe"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expect(
      screen.getByText(
        "Tu Viandita no recibirá pedidos del 10/09/26 al 18/09/26.",
      ),
    ).toBeInTheDocument()
  })

  it("keeps both selected closure periods after dismissing their notices", async () => {
    const user = userEvent.setup()
    const first = closure({
      starts_on: "2026-09-10",
      ends_on: "2026-09-18",
      period: "10/09/26 al 18/09/26",
    })
    const second = closure({
      id: 2,
      provider_id: 2,
      provider_name: "Endulzate by Noe",
      starts_on: "2026-09-14",
      ends_on: "2026-09-16",
      period: "14/09/26 al 16/09/26",
    })
    renderMenu({
      schedules: [],
      closures: [first, second],
      providers: [
        { id: 1, name: "Tu Viandita", order_deadline: null },
        { id: 2, name: "Endulzate by Noe", order_deadline: null },
        { id: 3, name: "Otro proveedor", order_deadline: null },
      ],
    })

    for (const button of screen.getAllByRole("button", {
      name: "Cerrar aviso",
    })) {
      await user.click(button)
    }
    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Otro proveedor"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expect(
      screen.queryByText("Tu Viandita no está disponible"),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByText("Endulzate by Noe no está disponible"),
    ).not.toBeInTheDocument()
    expect(
      screen.getByText(
        "Tu Viandita no recibirá pedidos del 10/09/26 al 18/09/26. Endulzate by Noe no recibirá pedidos del 14/09/26 al 16/09/26.",
      ),
    ).toBeInTheDocument()
  })
  it("says nothing about a closure that already ended before the selected day", () => {
    renderMenu({
      closures: [closure({ starts_on: "2026-09-01", ends_on: "2026-09-10" })],
    })

    expect(screen.queryByText(/Tu Viandita no est/)).not.toBeInTheDocument()
  })

  it("keeps the usual empty message with every provider selected, even if one closed", () => {
    renderMenu({
      schedules: [],
      closures: [
        closure({
          starts_on: "2026-09-10",
          ends_on: "2026-09-18",
          period: "10/09/26 al 18/09/26",
        }),
      ],
    })

    expect(screen.getByText("Menú no disponible")).toBeInTheDocument()
    expect(
      screen.getByText(
        "Todavía no hay viandas publicadas para este día. Volvé a consultar más tarde.",
      ),
    ).toBeInTheDocument()
    expect(screen.queryByText(/no recibirá pedidos/)).not.toBeInTheDocument()
  })

  it("explains the provider and closure period in the filtered empty state", async () => {
    const user = userEvent.setup()
    renderMenu({
      schedules: [],
      closures: [
        closure({
          starts_on: "2026-09-10",
          ends_on: "2026-09-18",
          period: "10/09/26 al 18/09/26",
        }),
      ],
    })

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Endulzate by Noe"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expect(screen.getByText("Menú no disponible")).toBeInTheDocument()
    expect(
      screen.getByText(
        "Tu Viandita no recibirá pedidos del 10/09/26 al 18/09/26.",
      ),
    ).toBeInTheDocument()
  })

  it("does not blame a closed provider when filtering by another one", async () => {
    const user = userEvent.setup()
    renderMenu({
      schedules: [],
      closures: [
        closure({
          starts_on: "2026-09-10",
          ends_on: "2026-09-18",
          period: "10/09/26 al 18/09/26",
        }),
      ],
    })

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Tu Viandita"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expect(screen.queryByText(/no recibirá pedidos/)).not.toBeInTheDocument()
    expect(
      screen.getByText(
        "No encontramos viandas disponibles entre los proveedores seleccionados. Volvé a consultar más tarde.",
      ),
    ).toBeInTheDocument()
  })

  it("keeps the usual empty message when no closure explains it", () => {
    renderMenu({ schedules: [] })

    expect(
      screen.getByText(
        "Todavía no hay viandas publicadas para este día. Volvé a consultar más tarde.",
      ),
    ).toBeInTheDocument()
  })
})
