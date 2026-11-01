import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import type { BenefitConfiguration } from "@/types/serializers"

import Index from "./index"

let currentFlashNotice: string | undefined = undefined
let mockIsMobile = false

vi.mock("@/hooks/use-mobile", () => ({
  useIsMobile: () => mockIsMobile,
}))

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    usePage: () => ({
      flash: { notice: currentFlashNotice },
      props: { locale: "es" },
    }),
    useForm: (initialValues: Record<string, unknown>) => ({
      data: initialValues,
      setData: vi.fn(),
      post: vi.fn(),
      processing: false,
      errors: {},
      clearErrors: vi.fn(),
      transform: vi.fn(),
    }),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

describe("Admin::BenefitConfigurations Index Page", () => {
  const currentConfig: BenefitConfiguration = {
    id: 1,
    subsidy_percentage: 50,
    benefit_rules: [
      {
        id: 2,
        type: "MonthlyBenefit",
        max_price: 150,
        limit: 20,
        effective_from: "2026-09-01",
        deadline_date: null,
        deadline_days: null,
        min_years: null,
        created_at: "2026-09-01T10:00:00Z",
      },
    ],
    created_at: "2026-09-01T10:00:00Z",
    created_by_name: "Admin User",
  }

  const pendingConfig: BenefitConfiguration = {
    id: 2,
    subsidy_percentage: 60,
    benefit_rules: [
      {
        id: 2,
        type: "MonthlyBenefit",
        max_price: 200,
        limit: 25,
        effective_from: "2026-09-01",
        deadline_date: null,
        deadline_days: null,
        min_years: null,
        created_at: "2026-09-01T10:00:00Z",
      },
    ],
    created_at: "2026-09-20T10:00:00Z",
    created_by_name: "Admin User",
  }

  beforeEach(() => {
    vi.clearAllMocks()
    currentFlashNotice = undefined
    mockIsMobile = false
  })

  it("renders empty state when there is no current configuration", () => {
    render(
      <Index
        benefit_configurations={[]}
        special_subsidies={[]}
        employees={[]}
        pending_base_subsidies={[]}
        base_subsidy={null}
        configurable_month={""}
        debt_alert_threshold={2000}
      />,
    )

    expect(
      screen.getByText(/todavía no configuraste el subsidio base/i),
    ).toBeInTheDocument()
  })

  it("offers navigation back to the RRHH account", () => {
    render(
      <Index
        benefit_configurations={[]}
        special_subsidies={[]}
        employees={[]}
        pending_base_subsidies={[]}
        base_subsidy={null}
        configurable_month={""}
        debt_alert_threshold={2000}
      />,
    )

    expect(
      screen.getByRole("link", { name: "Volver a Cuenta" }),
    ).toHaveAttribute("href", "/rrhh/cuenta")
  })

  it("renders current benefit configuration details when present", () => {
    render(
      <Index
        benefit_configurations={[]}
        special_subsidies={[]}
        employees={[]}
        pending_base_subsidies={[]}
        base_subsidy={currentConfig}
        configurable_month={""}
        debt_alert_threshold={2000}
      />,
    )

    expect(screen.getByText("50%")).toBeInTheDocument()
    expect(screen.getByText("≤$150")).toBeInTheDocument()
    expect(screen.getByText("20")).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Editar" })).toBeInTheDocument()
  })

  it("toggles inline editing form when clicking 'Editar'", async () => {
    const user = userEvent.setup()
    render(
      <Index
        benefit_configurations={[]}
        special_subsidies={[]}
        employees={[]}
        pending_base_subsidies={[]}
        base_subsidy={currentConfig}
        configurable_month={"2026-12-12"}
        debt_alert_threshold={2000}
      />,
    )

    await user.click(screen.getByRole("button", { name: "Editar" }))

    expect(
      screen.getByRole("button", { name: /programar subsidio/i }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: /cancelar/i }),
    ).toBeInTheDocument()
    expect(
      screen.getByText(/los cambios se aplicarán en el próximo período/i),
    ).toBeInTheDocument()

    // Clicking cancel toggles back to read-only view
    await user.click(screen.getByRole("button", { name: /cancelar/i }))
    expect(screen.getByRole("button", { name: "Editar" })).toBeInTheDocument()
  })

  it("opens bottom sheet when clicking 'Editar' on mobile", async () => {
    mockIsMobile = true
    const user = userEvent.setup()
    render(
      <Index
        benefit_configurations={[]}
        special_subsidies={[]}
        employees={[]}
        pending_base_subsidies={[]}
        base_subsidy={currentConfig}
        configurable_month={"2026-12-12"}
        debt_alert_threshold={2000}
      />,
    )

    await user.click(screen.getByRole("button", { name: "Editar" }))

    const sheet = screen.getByRole("dialog")
    expect(sheet).toBeInTheDocument()
    expect(within(sheet).getByText("Subsidio Base")).toBeInTheDocument()
    expect(
      within(sheet).getByRole("button", {
        name: /programar subsidio|guardar cambios/i,
      }),
    ).toBeInTheDocument()
  })

  it("renders scheduled changes when pending_base_subsidies are present", () => {
    render(
      <Index
        benefit_configurations={[]}
        special_subsidies={[]}
        employees={[]}
        pending_base_subsidies={[pendingConfig]}
        base_subsidy={currentConfig}
        configurable_month={"2026-12-12"}
        debt_alert_threshold={2000}
      />,
    )

    expect(
      screen.getByText(
        /hay un cambio programado para el sábado 12 de diciembre/i,
      ),
    ).toBeInTheDocument()
    expect(screen.getByText(/se descuenta 60%/i)).toBeInTheDocument()
  })

  it("does not render scheduled changes alert when there are no pending subsidies", () => {
    render(
      <Index
        benefit_configurations={[currentConfig]}
        special_subsidies={[]}
        employees={[]}
        pending_base_subsidies={[]}
        base_subsidy={currentConfig}
        configurable_month={"2026-12-12"}
        debt_alert_threshold={2000}
      />,
    )

    expect(
      screen.queryByText(/hay un cambio programado/i),
    ).not.toBeInTheDocument()
  })

  it("shows the debt alert threshold set by HR", () => {
    render(
      <Index
        benefit_configurations={[]}
        special_subsidies={[]}
        employees={[]}
        pending_base_subsidies={[]}
        base_subsidy={null}
        configurable_month={""}
        debt_alert_threshold={2500}
      />,
    )

    expect(screen.getByText("Alerta de deuda")).toBeInTheDocument()
    expect(screen.getByText("$2.500")).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Editar monto" }),
    ).toBeInTheDocument()
  })
})
