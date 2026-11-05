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
      screen.getByText("Fotografía sin cierre verificado"),
    ).toBeInTheDocument()
    expect(
      screen.getByText("Datos registrados el 31/10, 23:55"),
    ).toBeInTheDocument()
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
      screen.getByText("Cupo no utilizado al cierre").parentElement,
    ).toHaveTextContent("Sin datos")
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

  it("keeps missing historical values unknown and never draws a bar for them", async () => {
    const user = userEvent.setup()
    const data = history()
    data.period.state = "missing_snapshot"
    data.period.source = "historical_reconstruction"
    data.period.captured_at = null
    data.metrics.employees = null
    data.metrics.eligible_employees = null
    data.metrics.participation_percent = null
    data.metrics.monthly_quota_meals = null
    data.trends[0].metrics.confirmed_meals = null
    data.comparisons[0].quality = "not_comparable"
    render(<BenefitUsageHistoricalMetrics history={data} />)
    expect(screen.getByText("Sin fotografía histórica")).toBeInTheDocument()
    expect(
      screen.getByText(/No hay fotografía de este mes/),
    ).toBeInTheDocument()
    await open(user, "Participación de empleados")
    expect(
      screen.getByText("Empleados del período").parentElement,
    ).toHaveTextContent("Sin datos")
    await open(user, "Últimos cuatro meses")
    const trend = within(
      screen.getByRole("list", { name: "Viandas confirmadas" }),
    ).getAllByRole("listitem")[0]
    expect(trend).toHaveTextContent("Sin datos")
    expect(trend.querySelector('[aria-hidden="true"]')).toBeNull()
    await open(user, "Comparación con el mes anterior")
    expect(
      screen.getByText("No hay una comparación confiable con el mes anterior."),
    ).toBeInTheDocument()
    expect(
      screen.queryByText("+8,77 puntos porcentuales"),
    ).not.toBeInTheDocument()
  })

  it("shows the unused quota only for a verified close", async () => {
    const user = userEvent.setup()
    const data = history()
    data.period.state = "closed"
    data.metrics.monthly_unused_closed_meals = 640
    data.unavailable_reasons = {}
    render(<BenefitUsageHistoricalMetrics history={data} />)
    expect(screen.getByText("Cierre verificado")).toBeInTheDocument()
    expect(screen.queryByText(/Cierre no verificado/)).not.toBeInTheDocument()
    await open(user, "Capacidad del beneficio")
    expect(
      screen.getByText("Cupo no utilizado al cierre").parentElement,
    ).toHaveTextContent("640")
  })
})
