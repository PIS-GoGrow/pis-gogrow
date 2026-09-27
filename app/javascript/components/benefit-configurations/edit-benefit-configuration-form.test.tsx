import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it, vi } from "vitest"

import type { BenefitConfiguration } from "@/types/serializers"

import EditBenefitConfigurationForm from "./edit-benefit-configuration-form"

const postMock = vi.fn()
let currentFormData: Record<string, unknown> = {}
let currentFormErrors: Record<string, string[] | undefined> = {}
let transformCallback: ((data: Record<string, unknown>) => unknown) | null =
  null

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    useForm: (initialValues: Record<string, unknown>) => {
      currentFormData = { ...initialValues }
      return {
        data: currentFormData,
        setData: (key: string, val: unknown) => {
          currentFormData[key] = val
        },
        post: (...args: unknown[]) => {
          postMock(...args)
        },
        errors: currentFormErrors,
        clearErrors: vi.fn(),
        transform: (fn: (data: Record<string, unknown>) => unknown) => {
          transformCallback = fn
        },
      }
    },
  }
})

describe("EditBenefitConfigurationForm", () => {
  const defaultValues = {
    subsidy_percentage: 50 as const,
    max_voucher_price: 150 as const,
    monthly_voucher_limit: 20 as const,
  }

  const pendingBenefitConfiguration: BenefitConfiguration = {
    id: 99,
    subsidy_percentage: 60,
    max_voucher_price: 200,
    monthly_voucher_limit: 25,
    effective_from: "2026-10-01",
    created_at: "2026-09-21T00:00:00Z",
    created_by_name: "Admin User",
  }

  beforeEach(() => {
    vi.clearAllMocks()
    currentFormData = {}
    currentFormErrors = {}
    transformCallback = null
  })

  it("renders input fields with default values", () => {
    render(
      <EditBenefitConfigurationForm
        defaultValues={defaultValues}
        onCancel={vi.fn()}
        onSuccess={vi.fn()}
      />,
    )

    expect(screen.getByLabelText(/se descuenta/i)).toHaveValue(50)
    expect(
      screen.getByLabelText(/cuando el precio por vianda es/i),
    ).toHaveValue(150)
    expect(
      screen.getByLabelText(/hasta un límite por empleado de/i),
    ).toHaveValue(20)
  })

  it("submits the form with replace_pending: false when there is no pending configuration", async () => {
    const user = userEvent.setup()
    const onSuccess = vi.fn()
    render(
      <EditBenefitConfigurationForm
        defaultValues={defaultValues}
        onCancel={vi.fn()}
        onSuccess={onSuccess}
      />,
    )

    const submitBtn = screen.getByRole("button", {
      name: /programar subsidio/i,
    })
    await user.click(submitBtn)

    expect(transformCallback).not.toBeNull()
    const payload = transformCallback!({
      subsidy_percentage: 50,
      max_voucher_price: 150,
      monthly_voucher_limit: 20,
    })

    expect(payload).toEqual({
      benefit_configuration: {
        subsidy_percentage: 50,
        max_voucher_price: 150,
        monthly_voucher_limit: 20,
      },
      replace_pending: false,
    })
    expect(postMock).toHaveBeenCalledOnce()
  })

  it("shows conflict alert when a pending configuration already exists", async () => {
    const user = userEvent.setup()
    render(
      <EditBenefitConfigurationForm
        defaultValues={defaultValues}
        pendingBenefitConfiguration={pendingBenefitConfiguration}
        onCancel={vi.fn()}
        onSuccess={vi.fn()}
      />,
    )

    const submitBtn = screen.getByRole("button", {
      name: /programar subsidio/i,
    })
    await user.click(submitBtn)

    expect(postMock).not.toHaveBeenCalled()
    expect(
      screen.getByText(/ya hay un cambio programado para el próximo período/i),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: /mantener el programado/i }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: /reemplazar por este/i }),
    ).toBeInTheDocument()
  })

  it("cancels and keeps existing when clicking 'Mantener el programado'", async () => {
    const user = userEvent.setup()
    const onCancel = vi.fn()
    render(
      <EditBenefitConfigurationForm
        defaultValues={defaultValues}
        pendingBenefitConfiguration={pendingBenefitConfiguration}
        onCancel={onCancel}
        onSuccess={vi.fn()}
      />,
    )

    await user.click(
      screen.getByRole("button", { name: /programar subsidio/i }),
    )
    await user.click(
      screen.getByRole("button", { name: /mantener el programado/i }),
    )

    expect(onCancel).toHaveBeenCalledOnce()
    expect(postMock).not.toHaveBeenCalled()
  })

  it("replaces pending with replace_pending: true when clicking 'Reemplazar por este'", async () => {
    const user = userEvent.setup()
    render(
      <EditBenefitConfigurationForm
        defaultValues={defaultValues}
        pendingBenefitConfiguration={pendingBenefitConfiguration}
        onCancel={vi.fn()}
        onSuccess={vi.fn()}
      />,
    )

    await user.click(
      screen.getByRole("button", { name: /programar subsidio/i }),
    )
    await user.click(
      screen.getByRole("button", { name: /reemplazar por este/i }),
    )

    expect(transformCallback).not.toBeNull()
    const payload = transformCallback!({
      subsidy_percentage: 50,
      max_voucher_price: 150,
      monthly_voucher_limit: 20,
    })

    expect(payload).toEqual({
      benefit_configuration: {
        subsidy_percentage: 50,
        max_voucher_price: 150,
        monthly_voucher_limit: 20,
      },
      replace_pending: true,
    })
    expect(postMock).toHaveBeenCalledOnce()
  })

  it("calls onCancel when clicking Cancelar", async () => {
    const user = userEvent.setup()
    const onCancel = vi.fn()
    render(
      <EditBenefitConfigurationForm
        defaultValues={defaultValues}
        onCancel={onCancel}
        onSuccess={vi.fn()}
      />,
    )

    await user.click(screen.getByRole("button", { name: /cancelar/i }))
    expect(onCancel).toHaveBeenCalledOnce()
  })

  it("displays validation error messages when errors are present", () => {
    currentFormErrors = {
      subsidy_percentage: ["debe ser menor o igual a 100"],
      max_voucher_price: ["debe ser mayor que 0"],
      monthly_voucher_limit: ["debe ser un número entero"],
      effective_from: ["ya ha sido tomado"],
    }

    render(
      <EditBenefitConfigurationForm
        defaultValues={defaultValues}
        onCancel={vi.fn()}
        onSuccess={vi.fn()}
      />,
    )

    expect(screen.getByText("debe ser menor o igual a 100")).toBeInTheDocument()
    expect(screen.getByText("debe ser mayor que 0")).toBeInTheDocument()
    expect(screen.getByText("debe ser un número entero")).toBeInTheDocument()
    expect(screen.getByText("ya ha sido tomado")).toBeInTheDocument()
  })
})
