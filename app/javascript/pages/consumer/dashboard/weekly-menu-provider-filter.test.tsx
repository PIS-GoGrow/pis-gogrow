import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { useState } from "react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import type { ConsumerDashboardIndex } from "@/types"

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
    usePage: () => ({
      url: "/menu-semanal",
      props: { locale: "es", notifications: [] },
    }),
    Link: ({ href, children, ...props }: React.ComponentProps<"a">) => (
      <a href={href} {...props}>
        {children}
      </a>
    ),
  }
})

const providers: ConsumerDashboardIndex["providers"] = [
  { id: 1, name: "Tu Viandita", order_deadline: null },
  { id: 2, name: "Endulzate by Noe", order_deadline: null },
]

function schedule(
  id: number,
  provider: (typeof providers)[number],
  date = "2026-10-26",
): Schedule {
  return {
    id,
    date,
    remaining: 5,
    sold_out: false,
    orders_closed: false,
    menu: {
      id: id + 100,
      name: provider.id === 1 ? "Milanesa con papas" : "Tarta de verduras",
      description: null,
      price: 350,
      provider_id: provider.id,
      option_groups: [],
      provider_name: provider.name,
      home_delivery: true,
      rating_average: null,
      rating_count: 0,
      reviews: [],
    },
  }
}

const benefit: ConsumerDashboardIndex["benefit"] = {
  percentage: 50,
  monthly_limit: 20,
  monthly_used: 2,
  monthly_remaining: 18,
  specials: [],
}

function menuProps(overrides: Partial<MenuProps> = {}): MenuProps {
  return {
    name: "Sofía",
    date: "2026-10-26",
    setDate: vi.fn(),
    benefit,
    providers,
    schedules: [schedule(1, providers[0]), schedule(2, providers[1])],
    closures: [],
    cart: [],
    count: 0,
    total: 0,
    loading: false,
    openDetail: vi.fn(),
    ...overrides,
  }
}

function expectFilterLabel(label: string) {
  expect(
    screen.getByText(
      (_, element) =>
        element?.tagName === "SPAN" &&
        element.textContent === `Proveedores: ${label}`,
    ),
  ).toBeInTheDocument()
}

describe("WeeklyMenu provider filter", () => {
  beforeEach(() => {
    window.sessionStorage.clear()
  })

  it("shows only dishes from multiple selected provider IDs and deselects individually", async () => {
    const user = userEvent.setup()
    const thirdProvider = { id: 3, name: "La Cocina", order_deadline: null }
    const thirdSchedule = schedule(3, thirdProvider)
    thirdSchedule.menu.name = "Ensalada de quinoa"
    render(
      <ControlledWeeklyMenu
        {...menuProps({
          providers: [...providers, thirdProvider],
          schedules: [
            schedule(1, providers[0]),
            schedule(2, providers[1]),
            thirdSchedule,
          ],
        })}
      />,
    )

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("La Cocina"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expectFilterLabel("Tu Viandita, Endulzate by Noe")
    expect(screen.getByText("Milanesa con papas")).toBeInTheDocument()
    expect(screen.getByText("Tarta de verduras")).toBeInTheDocument()
    expect(screen.queryByText("Ensalada de quinoa")).not.toBeInTheDocument()

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Tu Viandita"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expectFilterLabel("Endulzate by Noe")
    expect(screen.queryByText("Milanesa con papas")).not.toBeInTheDocument()
    expect(screen.getByText("Tarta de verduras")).toBeInTheDocument()
    expect(screen.queryByText("Ensalada de quinoa")).not.toBeInTheDocument()

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Todos"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expectFilterLabel("Todos")
    expect(screen.getByText("Milanesa con papas")).toBeInTheDocument()
    expect(screen.getByText("Tarta de verduras")).toBeInTheDocument()
    expect(screen.getByText("Ensalada de quinoa")).toBeInTheDocument()
  })

  it("keeps all offers unrestricted when every provider is selected and a new one appears", async () => {
    const user = userEvent.setup()
    const firstProps = menuProps()
    const { rerender } = render(<ControlledWeeklyMenu {...firstProps} />)
    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Endulzate by Noe"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))
    expect(screen.queryByText("Tarta de verduras")).not.toBeInTheDocument()
    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Endulzate by Noe"))
    expect(screen.getByLabelText("Todos")).toBeChecked()
    await user.click(screen.getByRole("button", { name: "Aplicar" }))
    const newProvider = { id: 3, name: "Nuevo proveedor", order_deadline: null }
    const newSchedule = schedule(3, newProvider)
    newSchedule.menu.name = "Nueva oferta"
    rerender(
      <ControlledWeeklyMenu
        {...firstProps}
        providers={[...providers, newProvider]}
        schedules={[...firstProps.schedules, newSchedule]}
      />,
    )
    expectFilterLabel("Todos")
    expect(screen.getByText("Nueva oferta")).toBeInTheDocument()
    expect(screen.getByText("Milanesa con papas")).toBeInTheDocument()
    expect(screen.getByText("Tarta de verduras")).toBeInTheDocument()
    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    screen
      .getAllByRole("checkbox")
      .forEach((checkbox) => expect(checkbox).toBeChecked())
  })

  it("filters providers by ID even when their names match", async () => {
    const user = userEvent.setup()
    const sameNameProviders = providers.map((provider) => ({
      ...provider,
      name: "Mismo nombre",
    }))
    render(
      <ControlledWeeklyMenu
        {...menuProps({
          providers: sameNameProviders,
          schedules: [
            schedule(1, sameNameProviders[0]),
            schedule(2, sameNameProviders[1]),
          ],
        })}
      />,
    )

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getAllByLabelText("Mismo nombre")[1])
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expect(screen.getByText("Milanesa con papas")).toBeInTheDocument()
    expect(screen.queryByText("Tarta de verduras")).not.toBeInTheDocument()
  })
  it("shows every provider by default and filters by one provider", async () => {
    const user = userEvent.setup()
    render(<ControlledWeeklyMenu {...menuProps()} />)

    expectFilterLabel("Todos")
    expect(screen.getByText("Milanesa con papas")).toBeInTheDocument()
    expect(screen.getByText("Tarta de verduras")).toBeInTheDocument()

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Endulzate by Noe"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expectFilterLabel("Tu Viandita")
    expect(screen.getByText("Milanesa con papas")).toBeInTheDocument()
    expect(screen.queryByText("Tarta de verduras")).not.toBeInTheDocument()
  })

  it("keeps the provider filter when the selected day changes", async () => {
    const user = userEvent.setup()
    const firstProps = menuProps()
    const { rerender } = render(<ControlledWeeklyMenu {...firstProps} />)

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Endulzate by Noe"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    rerender(
      <ControlledWeeklyMenu
        {...firstProps}
        date="2026-10-27"
        schedules={[
          schedule(3, providers[0], "2026-10-27"),
          schedule(4, providers[1], "2026-10-27"),
        ]}
      />,
    )

    expectFilterLabel("Tu Viandita")
    expect(screen.getByText("Milanesa con papas")).toBeInTheDocument()
    expect(screen.queryByText("Tarta de verduras")).not.toBeInTheDocument()
  })

  it("removes the filter by applying Todos", async () => {
    const user = userEvent.setup()
    render(<ControlledWeeklyMenu {...menuProps()} />)

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Endulzate by Noe"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))
    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Todos"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expectFilterLabel("Todos")
    expect(screen.getByText("Milanesa con papas")).toBeInTheDocument()
    expect(screen.getByText("Tarta de verduras")).toBeInTheDocument()
  })

  it("distinguishes the unfiltered and filtered empty states", async () => {
    const user = userEvent.setup()
    render(<ControlledWeeklyMenu {...menuProps({ schedules: [] })} />)

    expect(
      screen.getByText(
        "Todavía no hay viandas publicadas para este día. Volvé a consultar más tarde.",
      ),
    ).toBeInTheDocument()

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Endulzate by Noe"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expect(
      screen.getByText(
        "No encontramos viandas disponibles entre los proveedores seleccionados. Volvé a consultar más tarde.",
      ),
    ).toBeInTheDocument()
  })
})
