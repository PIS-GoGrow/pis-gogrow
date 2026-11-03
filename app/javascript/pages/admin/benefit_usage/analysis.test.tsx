import {
  act,
  fireEvent,
  render,
  screen,
  waitFor,
  within,
} from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { type ReactNode, StrictMode } from "react"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

import { benefitUsageFixture } from "@/test/benefit-usage-fixture"
import type { AdminBenefitUsageAnalysis } from "@/types/serializers"

import Analysis from "./analysis"

const { visit } = vi.hoisted(() => ({ visit: vi.fn() }))
vi.mock("@inertiajs/react", async () => ({
  ...(await vi.importActual("@inertiajs/react")),
  Head: () => null,
  router: { get: visit },
}))
vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: ReactNode }) => <div>{children}</div>,
}))

const props: AdminBenefitUsageAnalysis = {
  month: "2026-10",
  current_month: "2026-10",
  months: [
    { key: "2026-10", label: "Octubre 2026" },
    { key: "2026-09", label: "Septiembre 2026" },
  ],
}
const response = (data: unknown, status = 200) =>
  new Response(JSON.stringify(data), {
    status,
    headers: { "Content-Type": "application/json" },
  })
function deferred() {
  let resolve!: (value: Response) => void
  const promise = new Promise<Response>((done) => {
    resolve = done
  })
  return { promise, resolve }
}

async function openSection(
  user: ReturnType<typeof userEvent.setup>,
  name: string,
) {
  const trigger = screen.getByRole("button", { name: new RegExp(name) })
  expect(trigger).toHaveAttribute("aria-expanded", "false")
  await user.click(trigger)
  expect(trigger).toHaveAttribute("aria-expanded", "true")
  return trigger
}

describe("Uso del beneficio", () => {
  const fetchMock = vi.fn<typeof fetch>()
  beforeEach(() => {
    visit.mockReset()
    fetchMock.mockReset().mockResolvedValue(response(benefitUsageFixture()))
    vi.stubGlobal("fetch", fetchMock)
    Element.prototype.scrollIntoView = vi.fn()
  })
  afterEach(() => vi.unstubAllGlobals())

  it("loads once in StrictMode and never generates AI automatically", async () => {
    const user = userEvent.setup()
    render(
      <StrictMode>
        <Analysis {...props} />
      </StrictMode>,
    )
    expect(
      screen.getByRole("status", {
        name: "Cargando estadísticas del beneficio",
      }),
    ).toBeInTheDocument()
    await screen.findByText("$5.425,25")
    expect(
      screen
        .getByRole("heading", { name: "Resumen con IA" })
        .compareDocumentPosition(
          screen.getByRole("heading", { name: "Resumen del mes" }),
        ) & Node.DOCUMENT_POSITION_FOLLOWING,
    ).toBeTruthy()
    expect(
      screen.getByRole("button", { name: "Generar resumen con IA" }),
    ).toBeEnabled()
    expect(
      screen.getByRole("button", { name: "Resumen con IA" }),
    ).toHaveAttribute("aria-expanded", "true")
    expect(
      screen.getByRole("button", { name: /Resumen del mes/ }),
    ).toHaveAttribute("aria-expanded", "true")
    for (const name of [
      "Capacidad del beneficio",
      "Participación de empleados",
      "Últimos cuatro meses",
      "Limitaciones de los datos",
    ]) {
      expect(screen.getByRole("button", { name })).toHaveAttribute(
        "aria-expanded",
        "false",
      )
    }
    expect(fetchMock).toHaveBeenCalledTimes(1)
    expect(fetchMock.mock.calls[0][0]).toBe("/rrhh/uso-beneficio?month=2026-10")
    await openSection(user, "Participación de empleados")
    expect(screen.getByText("72%")).toBeInTheDocument()
    expect(screen.getByText("Empleados")).toBeInTheDocument()
    expect(
      screen.getByText("Promedio de viandas por empleado"),
    ).toBeInTheDocument()
    expect(screen.getByText("4,5")).toBeInTheDocument()
    expect(
      screen.getByText(
        "Promedio calculado sobre todos los empleados actuales de la empresa, incluidos aquellos que no realizaron pedidos.",
      ),
    ).toBeInTheDocument()
    expect(screen.queryByText("Elegibles sin pedidos")).not.toBeInTheDocument()
    await openSection(user, "Capacidad del beneficio")
    expect(screen.getByText("257")).toBeInTheDocument()
    expect(screen.getByRole("progressbar")).toHaveAttribute(
      "aria-valuetext",
      "43 de 300 viandas utilizadas o reservadas",
    )
    expect(
      screen.getByRole("link", { name: "Volver a Inicio" }),
    ).toHaveAttribute("href", "/rrhh/inicio?month=2026-10")
    expect(screen.getByText("Mes abierto · parcial")).toBeInTheDocument()
  })

  it("preserves unknowns and zero while omitting unreliable historical capacity", async () => {
    const user = userEvent.setup()
    const data = benefitUsageFixture()
    data.period.closed = true
    data.consumption.confirmed_orders = 0
    data.consumption.confirmed_meals = 0
    data.consumption.company_subsidy_amount = "9007199254740993.01"
    data.capacity = {
      monthly_quota_meals: null,
      monthly_available_meals: null,
      monthly_pending_reserved_meals: null,
    }
    data.participation = {
      percent: null,
      eligible_employees: null,
      eligible_without_orders: null,
    }
    data.employee_activity = {
      current_employees: 10,
      employees_with_confirmed_orders: 0,
      average_confirmed_meals_per_current_employee: 0,
    }
    fetchMock.mockResolvedValue(response(data))
    render(<Analysis {...props} />)
    await screen.findByText("$9.007.199.254.740.993,01")
    expect(
      screen.queryByRole("button", { name: "Capacidad del beneficio" }),
    ).not.toBeInTheDocument()
    await openSection(user, "Actividad de empleados")
    expect(
      screen.getByText("Empleados con pedidos confirmados"),
    ).toBeInTheDocument()
    expect(screen.getByText("Empleados actuales")).toBeInTheDocument()
    expect(
      screen.getByText("Promedio sobre la nómina actual"),
    ).toBeInTheDocument()
    expect(
      screen.getByText(
        "Este promedio utiliza la nómina actual como referencia. La cantidad de empleados al cierre de ese mes puede haber sido diferente.",
      ),
    ).toBeInTheDocument()
    expect(screen.getAllByText("0").length).toBeGreaterThanOrEqual(3)
    expect(screen.queryByRole("progressbar")).not.toBeInTheDocument()
    await openSection(user, "Últimos cuatro meses")
    const trends = screen.getByRole("list", { name: "Viandas confirmadas" })
    const unknownMonth = within(trends).getAllByRole("listitem")[1]
    expect(unknownMonth).toHaveTextContent("Dato no disponible")
    expect(unknownMonth.querySelector('[aria-hidden="true"]')).toBeNull()
  })

  it("shows 20% used capacity for 4 of 20 reserved or used meals", async () => {
    const user = userEvent.setup()
    const data = benefitUsageFixture()
    data.capacity = {
      monthly_quota_meals: 20,
      monthly_available_meals: 16,
      monthly_pending_reserved_meals: 4,
    }
    fetchMock.mockResolvedValue(response(data))
    render(<Analysis {...props} />)
    await screen.findByText("$5.425,25")
    await openSection(user, "Capacidad del beneficio")
    expect(screen.getByRole("progressbar")).toHaveAttribute(
      "aria-valuenow",
      "20",
    )
    expect(screen.getByRole("progressbar")).toHaveAttribute(
      "aria-valuetext",
      "4 de 20 viandas utilizadas o reservadas",
    )
    expect(
      screen.getByText("4 de 20 viandas utilizadas o reservadas"),
    ).toBeInTheDocument()
    expect(screen.getByText("16")).toBeInTheDocument()
    expect(screen.getByText("20")).toBeInTheDocument()
    expect(screen.getByText("4")).toBeInTheDocument()
  })

  it("does not render a capacity bar when a required value is unknown", async () => {
    const user = userEvent.setup()
    const data = benefitUsageFixture()
    data.capacity.monthly_pending_reserved_meals = null
    fetchMock.mockResolvedValue(response(data))
    render(<Analysis {...props} />)
    await screen.findByText("$5.425,25")
    await openSection(user, "Capacidad del beneficio")
    expect(screen.queryByRole("progressbar")).not.toBeInTheDocument()
    expect(
      screen.getByText(
        /Faltan datos confiables para informar el cupo completo/,
      ),
    ).toBeInTheDocument()
  })

  it("expands and collapses every main card through its accessible trigger", async () => {
    const user = userEvent.setup()
    render(<Analysis {...props} />)
    await screen.findByText("$5.425,25")
    const sections = [
      ["Resumen con IA", true],
      ["Resumen del mes", true],
      ["Capacidad del beneficio", false],
      ["Participación de empleados", false],
      ["Últimos cuatro meses", false],
      ["Limitaciones de los datos", false],
    ] as const

    for (const [name, initiallyOpen] of sections) {
      const trigger = screen.getByRole("button", { name: new RegExp(name) })
      expect(trigger).toHaveAttribute(
        "aria-expanded",
        initiallyOpen ? "true" : "false",
      )
      await user.click(trigger)
      expect(trigger).toHaveAttribute(
        "aria-expanded",
        initiallyOpen ? "false" : "true",
      )
      await user.click(trigger)
      expect(trigger).toHaveAttribute(
        "aria-expanded",
        initiallyOpen ? "true" : "false",
      )
    }
  })

  it.each([
    ["440.25", "$440,25", false],
    ["1250.50", "$1.250,50", false],
    ["125000.00", "$125.000,00", false],
    ["9007199254740993.01", "$9.007.199.254.740.993,01", true],
    [null, "Dato no disponible", true],
  ])(
    "keeps subsidy amount %s on one line",
    async (amount, expected, stacked) => {
      const data = benefitUsageFixture()
      data.consumption.company_subsidy_amount = amount
      fetchMock.mockResolvedValue(response(data))
      render(<Analysis {...props} />)
      const label = await screen.findByText(
        "Subsidio comprometido por la empresa, sin IVA",
      )
      const row = label.parentElement!
      const value = within(row).getByText(expected)
      expect(value).toHaveClass(
        "whitespace-nowrap",
        "tabular-nums",
        "max-w-full",
      )
      expect(row).toHaveClass(
        stacked ? "grid-cols-1" : "grid-cols-[minmax(0,1fr)_auto]",
      )
    },
  )

  it("keeps all monthly indicators, trends and expandable data limitations without anomaly cards", async () => {
    const user = userEvent.setup()
    const data = benefitUsageFixture()
    data.anomalies = [
      {
        type: "increase",
        indicator: "confirmed_meals",
        month: "2026-08",
        current_value: 45,
        reference_value: 20,
        variation_percent: 125,
      },
    ]
    fetchMock.mockResolvedValue(response(data))
    render(<Analysis {...props} />)
    await screen.findByText("$5.425,25")
    for (const label of [
      "Viandas confirmadas",
      "Pedidos confirmados",
      "Viandas con subsidio mensual",
      "Viandas sin subsidio mensual",
      "Subsidio comprometido por la empresa, sin IVA",
      "Pendientes de confirmación: 2 pedidos · 3 viandas.",
    ]) {
      expect(screen.getAllByText(label).length).toBeGreaterThan(0)
    }
    expect(
      screen.getByRole("heading", { name: "Últimos cuatro meses" }),
    ).toBeInTheDocument()
    expect(screen.queryByText("Variaciones destacadas")).not.toBeInTheDocument()
    await openSection(user, "Últimos cuatro meses")
    const trendDetails = screen.getByRole("button", {
      name: "Ver indicadores mensuales",
    })
    await user.click(trendDetails)
    expect(trendDetails).toHaveAttribute("aria-expanded", "true")
    expect(screen.getAllByText(/Mes anterior:/).length).toBeGreaterThan(0)
    const limitations = screen.getByRole("button", {
      name: "Limitaciones de los datos",
    })
    expect(limitations).toHaveAttribute("aria-expanded", "false")
    expect(
      screen.queryByText(
        "El mes abierto todavía puede incorporar pedidos y cambios.",
      ),
    ).not.toBeInTheDocument()
    await user.click(limitations)
    expect(limitations).toHaveAttribute("aria-expanded", "true")
    expect(
      screen.getByText(
        "El mes abierto todavía puede incorporar pedidos y cambios.",
      ),
    ).toBeInTheDocument()
    await user.click(limitations)
    expect(limitations).toHaveAttribute("aria-expanded", "false")
    const explanation = screen.getByRole("button", {
      name: "Cómo se calcula el subsidio",
    })
    await user.click(explanation)
    expect(
      screen.getByText(
        /Una vianda sin subsidio mensual puede tener un beneficio especial/,
      ),
    ).toBeInTheDocument()
  })

  it("groups repeated historical warnings but preserves specific limitations", async () => {
    const user = userEvent.setup()
    const data = benefitUsageFixture()
    data.warnings = [
      { code: "trend_monthly_subsidy_unknown", month: "2026-07" },
      { code: "trend_monthly_subsidy_unknown", month: "2026-08" },
      { code: "benefit_consumer_mismatch" },
    ]
    fetchMock.mockResolvedValue(response(data))
    render(<Analysis {...props} />)
    await screen.findByText("$5.425,25")
    await openSection(user, "Limitaciones de los datos")
    expect(
      screen.getByText(
        "Algunas estadísticas históricas no pueden calcularse completamente con los registros disponibles.",
      ),
    ).toBeInTheDocument()
    expect(
      screen.getAllByText(
        "No se conoce la cantidad de viandas con subsidio mensual.",
      ),
    ).toHaveLength(1)
    expect(
      screen.getByText(
        "Hay beneficios cuyo titular no coincide con el empleado del pedido.",
      ),
    ).toBeInTheDocument()
    expect(screen.queryByText(/Julio 2026:/)).not.toBeInTheDocument()
    expect(screen.queryByText(/Agosto 2026:/)).not.toBeInTheDocument()
  })

  it("does not invent a data limitations card when there are no warnings", async () => {
    const data = benefitUsageFixture()
    data.warnings = []
    fetchMock.mockResolvedValue(response(data))
    render(<Analysis {...props} />)
    await screen.findByText("$5.425,25")
    expect(
      screen.queryByRole("button", { name: "Limitaciones de los datos" }),
    ).not.toBeInTheDocument()
  })

  it("offers a manual retry after a statistics error", async () => {
    fetchMock.mockRejectedValueOnce(new Error("offline"))
    render(<Analysis {...props} />)
    await screen.findByText("No pudimos cargar las estadísticas")
    expect(fetchMock).toHaveBeenCalledTimes(1)
    fireEvent.click(screen.getByRole("button", { name: "Reintentar" }))
    await screen.findByText("$5.425,25")
    expect(fetchMock).toHaveBeenCalledTimes(2)
  })

  it("updates the month URL through the keyboard-accessible selector", async () => {
    const user = userEvent.setup()
    render(<Analysis {...props} />)
    await screen.findByText("$5.425,25")
    const select = screen.getByRole("combobox", { name: "Mes del análisis" })
    expect(select).toHaveClass(
      "rounded-full",
      "bg-muted",
      "border-solid",
      "border-border",
      "text-foreground",
    )
    select.focus()
    await user.keyboard("{Enter}")
    await user.keyboard("{End}{Enter}")
    expect(visit).toHaveBeenCalledWith(
      "/rrhh/analisis-beneficio?month=2026-09",
      {},
      expect.objectContaining({ preserveScroll: true }),
    )
  })

  it.each(["success", "error"] as const)(
    "recovers the initial statistics after unsuccessful month navigation (%s)",
    async (outcome) => {
      const user = userEvent.setup()
      const request = deferred()
      fetchMock.mockReturnValueOnce(request.promise)
      render(<Analysis {...props} />)
      await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(1))
      const signal = fetchMock.mock.calls[0][1]?.signal

      screen.getByRole("combobox", { name: "Mes del análisis" }).focus()
      await user.keyboard("{Enter}{End}{Enter}")
      expect(visit).toHaveBeenCalledTimes(1)
      const { onFinish } = visit.mock.calls[0][2] as { onFinish: () => void }
      act(onFinish)
      expect(signal?.aborted).toBe(false)

      await act(async () => {
        request.resolve(
          outcome === "success"
            ? response(benefitUsageFixture())
            : response({}, 500),
        )
        await request.promise
      })
      if (outcome === "error") {
        await screen.findByText("No pudimos cargar las estadísticas")
        await user.click(screen.getByRole("button", { name: "Reintentar" }))
      }
      await screen.findByText("$5.425,25")
      expect(
        screen.queryByRole("status", {
          name: "Cargando estadísticas del beneficio",
        }),
      ).not.toBeInTheDocument()
      expect(fetchMock).toHaveBeenCalledTimes(outcome === "success" ? 1 : 2)
    },
  )

  it("keeps a twelve-month menu in a scrollable, viewport-bound panel", async () => {
    const user = userEvent.setup()
    const months = [
      "2026-10",
      "2026-09",
      "2026-08",
      "2026-07",
      "2026-06",
      "2026-05",
      "2026-04",
      "2026-03",
      "2026-02",
      "2026-01",
      "2025-12",
      "2025-11",
    ].map((key) => ({ key, label: key }))
    render(<Analysis {...props} months={months} />)
    await screen.findByText("$5.425,25")
    const select = screen.getByRole("combobox", { name: "Mes del análisis" })
    select.focus()
    await user.keyboard("{Enter}")
    const menu = await screen.findByRole("listbox")
    expect(within(menu).getAllByRole("option")).toHaveLength(12)
    expect(
      menu.closest("[data-radix-popper-content-wrapper]"),
    ).toBeInTheDocument()
    expect(menu).toHaveClass(
      "max-h-[min(15rem,var(--radix-select-content-available-height))]",
      "[&_[data-radix-select-viewport]]:h-auto",
      "[&_[data-radix-select-viewport]]:max-h-52",
      "[&_[data-radix-select-viewport]]:min-h-0",
      "[&_[data-radix-select-viewport]]:overscroll-contain",
    )
    expect(menu.querySelector("[data-radix-select-viewport]")).toHaveStyle({
      overflow: "hidden auto",
    })
    expect(
      within(menu).getByRole("option", { name: "Este mes" }),
    ).toHaveAttribute("data-state", "checked")
  })

  it.each([
    [0, 0, "0 pedidos · 0 viandas"],
    [1, 1, "1 pedido · 1 vianda"],
    [2, 2, "2 pedidos · 2 viandas"],
    [1, 3, "1 pedido · 3 viandas"],
  ])(
    "pluralizes %i orders and %i meals independently",
    async (orders, meals, expected) => {
      const data = benefitUsageFixture()
      data.consumption.pending = {
        orders,
        meals,
        monthly_reserved_meals: meals,
      }
      fetchMock.mockResolvedValue(response(data))
      render(<Analysis {...props} />)
      expect(
        await screen.findByText(`Pendientes de confirmación: ${expected}.`),
      ).toBeInTheDocument()
    },
  )

  it("posts only the month with CSRF, prevents duplicates and renders AI as safe text", async () => {
    const user = userEvent.setup()
    const request = deferred()
    fetchMock
      .mockResolvedValueOnce(response(benefitUsageFixture()))
      .mockReturnValueOnce(request.promise)
    const meta = document.createElement("meta")
    meta.name = "csrf-token"
    meta.content = "csrf-test"
    document.head.append(meta)
    render(<Analysis {...props} />)
    await screen.findByText("$5.425,25")
    const button = screen.getByRole("button", {
      name: "Generar resumen con IA",
    })
    fireEvent.click(button)
    fireEvent.click(button)
    expect(fetchMock).toHaveBeenCalledTimes(2)
    expect(fetchMock.mock.calls[1][0]).toBe("/rrhh/uso-beneficio/resumen")
    expect(fetchMock.mock.calls[1][1]).toMatchObject({
      method: "POST",
      body: JSON.stringify({ month: "2026-10" }),
      credentials: "same-origin",
      headers: { "X-CSRF-Token": "csrf-test" },
    })
    expect(
      screen.getByRole("button", { name: "Generando resumen…" }),
    ).toBeDisabled()
    request.resolve(
      response({
        success: true,
        text: "<img src=x onerror=alert(1)>",
        month: "2026-10",
        generated_at: "2032-04-17T22:30:00-03:00",
        generated_at_label: "sábado 17 de abril a las 22:30",
        generated_by_ai: true,
      }),
    )
    await screen.findByText("<img src=x onerror=alert(1)>")
    expect(
      screen
        .getByText("Generado el sábado 17 de abril a las 22:30")
        .closest("time"),
    ).toHaveAttribute("datetime", "2032-04-17T22:30:00-03:00")
    expect(document.querySelector("img")).toBeNull()
    const aiTrigger = screen.getByRole("button", { name: "Resumen con IA" })
    await user.click(aiTrigger)
    expect(
      screen.queryByText("<img src=x onerror=alert(1)>"),
    ).not.toBeInTheDocument()
    await user.click(aiTrigger)
    expect(screen.getByText("<img src=x onerror=alert(1)>")).toBeInTheDocument()
    expect(fetchMock).toHaveBeenCalledTimes(2)
    meta.remove()
  })

  it("discards the completed summary and its generation date when changing periods", async () => {
    const user = userEvent.setup()
    fetchMock
      .mockResolvedValueOnce(response(benefitUsageFixture()))
      .mockResolvedValueOnce(
        response({
          success: true,
          text: "Resumen del mes anterior",
          month: "2026-10",
          generated_at: "2032-04-17T22:30:00-03:00",
          generated_at_label: "sábado 17 de abril a las 22:30",
          generated_by_ai: true,
        }),
      )
      .mockResolvedValueOnce(response(benefitUsageFixture("2026-09")))
    const view = render(<Analysis {...props} />)
    await screen.findByText("$5.425,25")
    await user.click(
      screen.getByRole("button", { name: "Generar resumen con IA" }),
    )
    await screen.findByText("Generado el sábado 17 de abril a las 22:30")

    screen.getByRole("combobox", { name: "Mes del análisis" }).focus()
    await user.keyboard("{Enter}{End}{Enter}")
    expect(
      screen.queryByText("Resumen del mes anterior"),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByText("Generado el sábado 17 de abril a las 22:30"),
    ).not.toBeInTheDocument()
    view.rerender(<Analysis {...props} month="2026-09" />)
    await screen.findByText("$5.425,25")
    expect(document.querySelector("time")).toBeNull()
    expect(fetchMock).toHaveBeenCalledTimes(3)
  })

  it.each([
    [429, "rate_limited", "Alcanzaste el límite de generación."],
    [
      503,
      "configuration_missing",
      "La generación con IA todavía no está configurada.",
    ],
    [502, "external_unavailable", "No pudimos generar el resumen."],
  ])(
    "keeps stats and does not retry after HTTP %s",
    async (status, code, message) => {
      fetchMock
        .mockResolvedValueOnce(response(benefitUsageFixture()))
        .mockResolvedValueOnce(
          response({ success: false, error: { code } }, status),
        )
      render(<Analysis {...props} />)
      await screen.findByText("$5.425,25")
      fireEvent.click(
        screen.getByRole("button", { name: "Generar resumen con IA" }),
      )
      await screen.findByText(new RegExp(message))
      expect(screen.getByText("$5.425,25")).toBeInTheDocument()
      expect(fetchMock).toHaveBeenCalledTimes(2)
    },
  )

  it("ignores late statistics even if transport ignores abort", async () => {
    const user = userEvent.setup()
    const old = deferred()
    fetchMock
      .mockReturnValueOnce(old.promise)
      .mockResolvedValueOnce(response(benefitUsageFixture("2026-09")))
    const view = render(<Analysis {...props} />)
    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(1))
    const signal = fetchMock.mock.calls[0][1]?.signal
    screen.getByRole("combobox", { name: "Mes del análisis" }).focus()
    await user.keyboard("{Enter}{End}{Enter}")
    expect(visit).toHaveBeenCalledTimes(1)
    expect(signal?.aborted).toBe(false)
    view.rerender(<Analysis {...props} month="2026-09" />)
    await screen.findByText("$5.425,25")
    expect(signal?.aborted).toBe(true)
    const stale = benefitUsageFixture()
    stale.consumption.company_subsidy_amount = "999999.00"
    await act(async () => {
      old.resolve(response(stale))
      await old.promise
    })
    expect(screen.queryByText("$999.999")).not.toBeInTheDocument()
    expect(fetchMock).toHaveBeenCalledTimes(2)
  })

  it("discards AI from the previous month and ignores late responses", async () => {
    const user = userEvent.setup()
    const old = deferred()
    fetchMock
      .mockResolvedValueOnce(response(benefitUsageFixture()))
      .mockReturnValueOnce(old.promise)
      .mockResolvedValueOnce(response(benefitUsageFixture("2026-09")))
    const view = render(<Analysis {...props} />)
    await screen.findByText("$5.425,25")
    fireEvent.click(
      screen.getByRole("button", { name: "Generar resumen con IA" }),
    )
    const signal = fetchMock.mock.calls[1][1]?.signal
    screen.getByRole("combobox", { name: "Mes del análisis" }).focus()
    await user.keyboard("{Enter}{End}{Enter}")
    expect(visit).toHaveBeenCalledTimes(1)
    expect(signal?.aborted).toBe(true)
    view.rerender(<Analysis {...props} month="2026-09" />)
    await screen.findByText("$5.425,25")
    expect(signal?.aborted).toBe(true)
    await act(async () => {
      old.resolve(
        response({
          success: true,
          month: "2026-10",
          text: "Resumen anterior",
          generated_at: "2032-04-17T22:30:00-03:00",
          generated_at_label: "sábado 17 de abril a las 22:30",
          generated_by_ai: true,
        }),
      )
      await old.promise
    })
    expect(screen.queryByText("Resumen anterior")).not.toBeInTheDocument()
    expect(
      screen.queryByText("Generado el sábado 17 de abril a las 22:30"),
    ).not.toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Generar resumen con IA" }),
    ).toBeEnabled()
    expect(fetchMock).toHaveBeenCalledTimes(3)
  })
})
