import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import type { BenefitConfiguration } from "@/types/serializers"

import Index from "./index"

let currentFlashNotice: string | undefined = undefined

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    usePage: () => ({
      flash: { notice: currentFlashNotice },
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
    max_voucher_price: 150,
    monthly_voucher_limit: 20,
    effective_from: "2026-09-01",
    created_at: "2026-09-01T10:00:00Z",
    created_by_name: "Admin User",
  }

  const pendingConfig: BenefitConfiguration = {
    id: 2,
    subsidy_percentage: 60,
    max_voucher_price: 200,
    monthly_voucher_limit: 25,
    effective_from: "2026-10-01",
    created_at: "2026-09-20T10:00:00Z",
    created_by_name: "Admin User",
  }

  beforeEach(() => {
    vi.clearAllMocks()
    currentFlashNotice = undefined
  })

  it("renders empty state when there is no current configuration", () => {
    render(
      <Index
        benefit_configurations={[]}
        current_benefit_configuration={null}
      />,
    )

    expect(
      screen.getByText(/todavía no configuraste el beneficio general/i),
    ).toBeInTheDocument()
  })

  it("renders current benefit configuration details when present", () => {
    render(
      <Index
        benefit_configurations={[currentConfig]}
        current_benefit_configuration={currentConfig}
      />,
    )

    expect(screen.getByText("50%")).toBeInTheDocument()
    expect(screen.getByText("≤$150")).toBeInTheDocument()
    expect(screen.getByText("20")).toBeInTheDocument()
    expect(screen.getByRole("button", { name: /editar/i })).toBeInTheDocument()
  })

  it("toggles inline editing form when clicking 'Editar'", async () => {
    const user = userEvent.setup()
    render(
      <Index
        benefit_configurations={[currentConfig]}
        current_benefit_configuration={currentConfig}
      />,
    )

    await user.click(screen.getByRole("button", { name: /editar/i }))

    expect(
      screen.getByRole("button", { name: /programar subsidio/i }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: /cancelar/i }),
    ).toBeInTheDocument()

    // Clicking cancel toggles back to read-only view
    await user.click(screen.getByRole("button", { name: /cancelar/i }))
    expect(screen.getByRole("button", { name: /editar/i })).toBeInTheDocument()
  })

  it("shows scheduled banner when flash.notice is present and allows dismissing it", async () => {
    const user = userEvent.setup()
    currentFlashNotice = "Subsidio programado para el próximo período."

    render(
      <Index
        benefit_configurations={[currentConfig, pendingConfig]}
        current_benefit_configuration={currentConfig}
      />,
    )

    expect(
      screen.getByText(/tus cambios están programados/i),
    ).toBeInTheDocument()

    const dismissBtn = screen.getByRole("button", { name: /cerrar aviso/i })
    await user.click(dismissBtn)

    expect(
      screen.queryByText(/tus cambios están programados/i),
    ).not.toBeInTheDocument()
  })

  it("does not show scheduled banner when there is no flash notice", () => {
    render(
      <Index
        benefit_configurations={[currentConfig, pendingConfig]}
        current_benefit_configuration={currentConfig}
      />,
    )

    expect(
      screen.queryByText(/tus cambios están programados/i),
    ).not.toBeInTheDocument()
  })
})
