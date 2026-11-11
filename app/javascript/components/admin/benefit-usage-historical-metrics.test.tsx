import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it } from "vitest"

import type { BenefitUsageHistory } from "@/types/benefit-usage"

import BenefitUsageHistoricalMetrics from "./benefit-usage-historical-metrics"

const metrics = {
  employees: 40,
  eligible_employees: 38,
  employees_with_confirmed_orders: 16,
  eligible_with_confirmed_orders: 16,
  eligible_without_orders: 22,
  participation_percent: "42.11",
  average_confirmed_meals_per_employee: "1.10",
  monthly_quota_meals: 760,
  monthly_subsidized_meals: 40,
  monthly_pending_reserved_meals: 4,
  monthly_available_meals: 716,
  monthly_unused_closed_meals: null,
  confirmed_orders: 30,
  confirmed_meals: 44,
  confirmed_meals_without_monthly_subsidy: 4,
  pending_orders: 3,
  pending_meals: 4,
  company_subsidy_amount: "6600.00",
}

function history(): BenefitUsageHistory {
  return {
    period: {
      month: "2026-10",
      state: "incomplete",
      source: "historical_snapshot",
      fictional: true,
      captured_at: "2026-10-31T23:55:00-03:00",
      calculation_version: 1,
    },
    metrics,
    unavailable_reasons: {
      period: "close_not_verified",
      monthly_unused_closed_meals: "close_not_verified",
    },
    trends: [
      {
        month: "2026-09",
        state: "incomplete",
        source: "historical_snapshot",
        metrics: {
          ...metrics,
          employees: 38,
          eligible_employees: 36,
          eligible_with_confirmed_orders: 12,
          participation_percent: "33.33",
          monthly_quota_meals: 720,
          confirmed_meals: 28,
          monthly_subsidized_meals: 28,
          company_subsidy_amount: "4200.00",
        },
      },
      {
        month: "2026-10",
        state: "incomplete",
        source: "historical_snapshot",
        metrics,
      },
    ],
    comparisons: [
      {
        from: "2026-09",
        to: "2026-10",
        quality: "capture_only",
        changes: {
          confirmed_meals: {
            reference: 28,
            current: 44,
            difference: 16,
            percent: "57.14",
            difference_points: null,
          },
          monthly_subsidized_meals: {
            reference: 28,
            current: 40,
            difference: 12,
            percent: "42.86",
            difference_points: null,
          },
          monthly_quota_meals: {
            reference: 720,
            current: 760,
            difference: 40,
            percent: "5.56",
            difference_points: null,
          },
          eligible_with_confirmed_orders: {
            reference: 12,
            current: 16,
            difference: 4,
            percent: "33.33",
            difference_points: null,
          },
          participation_percent: {
            reference: "33.33",
            current: "42.11",
            difference: null,
            percent: "26.32",
            difference_points: "8.77",
          },
          company_subsidy_amount: {
            reference: "4200.00",
            current: "6600.00",
            difference: "2400.00",
            percent: "57.14",
            difference_points: null,
          },
        },
      },
    ],
  }
}

async function open(user: ReturnType<typeof userEvent.setup>, name: string) {
  await user.click(screen.getByRole("button", { name }))
}

it("keeps historical cards independently sized and marks fictional data", async () => {
  const user = userEvent.setup()
  render(<BenefitUsageHistoricalMetrics history={history()} />)
  expect(screen.getByText("Datos de prueba")).toBeInTheDocument()
  const participation = screen.getByRole("button", {
    name: "Participación de empleados",
  })
  const capacity = screen.getByRole("button", {
    name: "Capacidad del beneficio",
  })
  expect(
    participation.closest('[data-slot="card-header"]')?.parentElement
      ?.parentElement,
  ).toHaveClass("grid", "items-start", "lg:grid-cols-2")
  expect(participation).toHaveAttribute("aria-expanded", "false")
  expect(capacity).toHaveAttribute("aria-expanded", "false")
  await user.click(participation)
  expect(capacity).toHaveAttribute("aria-expanded", "false")
  await user.click(participation)
  await user.click(capacity)
  expect(participation).toHaveAttribute("aria-expanded", "false")
  await user.click(participation)
  expect(participation).toHaveAttribute("aria-expanded", "true")
  expect(capacity).toHaveAttribute("aria-expanded", "true")
})

describe("estadísticas históricas de Uso del beneficio", () => {
  it("shows October snapshot values, capture time and a comparison of like-for-like September captures", async () => {
    const user = userEvent.setup()
    render(<BenefitUsageHistoricalMetrics history={history()} />)
    expect(
      screen.getByText("Última captura: 31/10/2026 · 23:55"),
    ).toBeInTheDocument()
    expect(
      screen.queryByText("Fotografía sin cierre verificado"),
    ).not.toBeInTheDocument()
    expect(screen.queryByText("Fotografía histórica")).not.toBeInTheDocument()
    expect(
      screen.queryByText(/Cierre no verificado\. Los valores/),
    ).not.toBeInTheDocument()
    expect(screen.getByText("Datos de prueba")).toBeInTheDocument()
    await open(user, "Participación de empleados")
    expect(
      screen.getByText("Empleados del período").parentElement,
    ).toHaveTextContent("40")
    expect(
      screen.getByText("Empleados elegibles").parentElement,
    ).toHaveTextContent("38")
    expect(
      screen.getByText("Elegibles con pedidos confirmados").parentElement,
    ).toHaveTextContent("16")
    expect(screen.getByText("Participación").parentElement).toHaveTextContent(
      "42,11 %",
    )
    await open(user, "Capacidad del beneficio")
    expect(
      screen.getByText("Cupo mensual total").parentElement,
    ).toHaveTextContent("760")
    expect(
      screen.getByText("Cupo disponible al momento de la captura")
        .parentElement,
    ).toHaveTextContent("716")
    expect(
      screen.queryByText("Cupo disponible al cierre"),
    ).not.toBeInTheDocument()
    await open(user, "Comparación con el mes anterior")
    const comparison =
      screen
        .getByText("Comparación de capturas; cierres no verificados")
        .closest("section") ??
      screen.getByText("Comparación de capturas; cierres no verificados")
        .parentElement!.parentElement!
    expect(comparison).toHaveTextContent("+8,77 puntos porcentuales")
    expect(comparison).toHaveTextContent("+16")
    expect(comparison).toHaveTextContent("+$2.400,00")
    expect(comparison).toHaveTextContent("+57,14 % respecto al mes anterior")
  })

  it("shows September's real capture time and no test badge for a non-fictional snapshot", () => {
    const data = history()
    data.period.month = "2026-09"
    data.period.captured_at = "2026-09-30T23:55:00-03:00"
    data.period.fictional = false
    render(<BenefitUsageHistoricalMetrics history={data} />)
    expect(
      screen.getByText("Última captura: 30/09/2026 · 23:55"),
    ).toBeInTheDocument()
    expect(screen.queryByText("Datos de prueba")).not.toBeInTheDocument()
  })

  it("explains a missing snapshot and shows only reconstructible consumption and trends", async () => {
    const user = userEvent.setup()
    const data = history()
    data.period.state = "missing_snapshot"
    data.period.source = "historical_reconstruction"
    data.period.captured_at = null
    data.metrics.employees = null
    data.metrics.eligible_employees = null
    data.metrics.participation_percent = null
    data.metrics.monthly_quota_meals = null
    data.metrics.monthly_subsidized_meals = null
    data.metrics.company_subsidy_amount = null
    data.trends[0].metrics.confirmed_meals = null
    data.comparisons[0].quality = "not_comparable"
    render(<BenefitUsageHistoricalMetrics history={data} />)
    expect(screen.getByText("Sin fotografía histórica")).toBeInTheDocument()
    expect(screen.queryByText(/Última captura:/)).not.toBeInTheDocument()
    expect(
      screen.getByText(
        "No hay estadísticas históricas completas para este mes",
      ),
    ).toBeInTheDocument()
    expect(
      screen.getByText(
        "No hay estadísticas históricas completas para este mes",
      ),
    ).toHaveClass("line-clamp-none", "min-w-0", "break-words")
    expect(
      screen.getByText(
        "No hay estadísticas históricas completas para este mes",
      ),
    ).not.toHaveClass("line-clamp-1")
    expect(
      screen.getByText(/Esto no significa que no haya habido actividad/),
    ).toBeInTheDocument()
    expect(
      screen.getByText("Información parcial recuperada"),
    ).toBeInTheDocument()
    expect(
      screen.getByText(/provienen de registros conservados/),
    ).toBeInTheDocument()
    expect(
      screen.getByText("Viandas confirmadas").parentElement,
    ).toHaveTextContent("44")
    expect(
      screen.queryByText("Viandas con subsidio mensual"),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByText("Subsidio comprometido sin IVA"),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByRole("button", { name: "Participación de empleados" }),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByRole("button", { name: "Capacidad del beneficio" }),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByRole("button", { name: "Comparación con el mes anterior" }),
    ).not.toBeInTheDocument()
    await open(user, "Últimos cuatro meses")
    const trends = within(
      screen.getByRole("list", { name: "Viandas confirmadas" }),
    ).getAllByRole("listitem")
    expect(trends).toHaveLength(1)
    expect(trends[0]).toHaveTextContent("44 viandas")
    expect(
      screen.queryByText("+8,77 puntos porcentuales"),
    ).not.toBeInTheDocument()
  })

  it("preserves known zero values without showing unknown metrics as zero", () => {
    const data = history()
    data.period.state = "missing_snapshot"
    data.period.source = "historical_reconstruction"
    data.period.captured_at = null
    data.metrics.confirmed_orders = 0
    data.metrics.confirmed_meals = 0
    data.metrics.monthly_subsidized_meals = null
    data.metrics.confirmed_meals_without_monthly_subsidy = null
    data.metrics.company_subsidy_amount = null
    data.trends = []
    data.comparisons = []
    render(<BenefitUsageHistoricalMetrics history={data} />)
    expect(
      screen.getByText("Pedidos confirmados").parentElement,
    ).toHaveTextContent("0")
    expect(
      screen.getByText("Viandas confirmadas").parentElement,
    ).toHaveTextContent("0")
    expect(
      screen.queryByText("Viandas con subsidio mensual"),
    ).not.toBeInTheDocument()
    expect(screen.queryByText("Sin datos")).not.toBeInTheDocument()
    expect(
      screen.queryByRole("button", { name: "Últimos cuatro meses" }),
    ).not.toBeInTheDocument()
  })

  it("does not render empty consumption or trend cards", () => {
    const data = history()
    data.period.state = "missing_snapshot"
    data.period.source = "historical_reconstruction"
    data.period.captured_at = null
    data.metrics.confirmed_orders = null
    data.metrics.confirmed_meals = null
    data.metrics.monthly_subsidized_meals = null
    data.metrics.confirmed_meals_without_monthly_subsidy = null
    data.metrics.company_subsidy_amount = null
    data.trends = []
    data.comparisons = []
    data.unavailable_reasons = { period: "historical_snapshot_missing" }
    render(<BenefitUsageHistoricalMetrics history={data} />)
    expect(
      screen.getByText(
        "No hay estadísticas históricas completas para este mes",
      ),
    ).toBeInTheDocument()
    expect(
      screen.queryByRole("button", { name: "Información parcial recuperada" }),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByRole("button", { name: "Últimos cuatro meses" }),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByRole("button", { name: "Limitaciones de los datos" }),
    ).not.toBeInTheDocument()
  })

  it("shows the unused quota only for a verified close", async () => {
    const user = userEvent.setup()
    const data = history()
    data.period.state = "closed"
    data.metrics.monthly_unused_closed_meals = 716
    data.unavailable_reasons = {}
    data.trends.forEach((entry) => {
      entry.state = "closed"
    })
    data.comparisons[0].quality = "verified_close"
    render(<BenefitUsageHistoricalMetrics history={data} />)
    expect(
      screen.getByText("Última captura: 31/10/2026 · 23:55"),
    ).toBeInTheDocument()
    expect(screen.queryByText("Cierre verificado")).not.toBeInTheDocument()
    expect(screen.queryByText(/Cierre no verificado/)).not.toBeInTheDocument()
    await open(user, "Capacidad del beneficio")
    expect(
      screen.getByText("Cupo disponible al cierre").parentElement,
    ).toHaveTextContent("716")
    expect(
      screen.queryByText("Cupo disponible al momento de la captura"),
    ).not.toBeInTheDocument()
    await open(user, "Comparación con el mes anterior")
    expect(screen.getByText("Cierres verificados")).toBeInTheDocument()
  })
})
