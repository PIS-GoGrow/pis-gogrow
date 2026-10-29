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
    expect(fetchMock).toHaveBeenCalledTimes(1)
    expect(fetchMock.mock.calls[0][0]).toBe("/rrhh/uso-beneficio?month=2026-10")
    expect(screen.getByText("72%")).toBeInTheDocument()
    expect(screen.getByText("257")).toBeInTheDocument()
    expect(screen.getByRole("progressbar")).toHaveAttribute(
      "aria-valuetext",
      "257 de 300 viandas disponibles",
    )
    expect(
      screen.getByRole("link", { name: "Volver a Inicio" }),
    ).toHaveAttribute("href", "/rrhh/inicio?month=2026-10")
    expect(
      screen.getAllByText("Mes abierto · parcial", {
        selector: '[data-slot="badge"]',
      }),
    ).toHaveLength(2)
  })

  it("preserves unknowns and zero, including historical capacity and unknown trend bars", async () => {
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
    fetchMock.mockResolvedValue(response(data))
    render(<Analysis {...props} />)
    await screen.findByText("$9.007.199.254.740.993,01")
    expect(screen.getAllByText("Dato no disponible").length).toBeGreaterThan(5)
    expect(screen.getAllByText("0")).toHaveLength(2)
    expect(screen.queryByRole("progressbar")).not.toBeInTheDocument()
    expect(
      screen.getByText(/No se conserva el estado del cupo/),
    ).toBeInTheDocument()
    const trends = screen.getByRole("list", { name: "Viandas confirmadas" })
    const unknownMonth = within(trends).getAllByRole("listitem")[1]
    expect(unknownMonth).toHaveTextContent("Dato no disponible")
    expect(unknownMonth.querySelector('[aria-hidden="true"]')).toBeNull()
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
      }),
    )
    await screen.findByText("<img src=x onerror=alert(1)>")
    expect(document.querySelector("img")).toBeNull()
    meta.remove()
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
    const old = deferred()
    fetchMock
      .mockReturnValueOnce(old.promise)
      .mockResolvedValueOnce(response(benefitUsageFixture("2026-09")))
    const view = render(<Analysis {...props} />)
    await waitFor(() => expect(fetchMock).toHaveBeenCalledTimes(1))
    const signal = fetchMock.mock.calls[0][1]?.signal
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
    view.rerender(<Analysis {...props} month="2026-09" />)
    await screen.findByText("$5.425,25")
    expect(signal?.aborted).toBe(true)
    await act(async () => {
      old.resolve(
        response({ success: true, month: "2026-10", text: "Resumen anterior" }),
      )
      await old.promise
    })
    expect(screen.queryByText("Resumen anterior")).not.toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Generar resumen con IA" }),
    ).toBeEnabled()
    expect(fetchMock).toHaveBeenCalledTimes(3)
  })
})
