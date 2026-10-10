import { render, screen, waitFor } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it, vi } from "vitest"

import DebtReminderDialog from "./debt-reminder-dialog"

const postMock = vi.fn()

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    usePage: () => ({
      props: { locale: "es" },
    }),
    router: {
      post: (...args: unknown[]) => {
        postMock(...args)
      },
    },
  }
})

describe("DebtReminderDialog", () => {
  const defaultProps = {
    accountId: 42,
    eligible: true,
    employeeName: "Juan Pérez",
    month: "Octubre 2026",
    amount: 1500,
  }

  beforeEach(() => {
    vi.clearAllMocks()
  })

  it("renderiza el botón trigger cuando eligible es true", () => {
    render(<DebtReminderDialog {...defaultProps} />)

    expect(
      screen.getByRole("button", { name: "Recordar pago pendiente" }),
    ).toBeInTheDocument()
  })

  it("no renderiza el botón trigger cuando eligible es false", () => {
    render(<DebtReminderDialog {...defaultProps} eligible={false} />)

    expect(
      screen.queryByRole("button", { name: "Recordar pago pendiente" }),
    ).not.toBeInTheDocument()
  })

  it("abre el diálogo con mensaje de confirmación y permite cancelar", async () => {
    const user = userEvent.setup()
    render(<DebtReminderDialog {...defaultProps} />)

    await user.click(
      screen.getByRole("button", { name: "Recordar pago pendiente" }),
    )

    expect(
      screen.getByText("Recordar pago pendiente", { selector: "h2" }),
    ).toBeInTheDocument()
    expect(screen.getByText(/Juan Pérez/)).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Enviar recordatorio" }),
    ).toBeInTheDocument()

    await user.click(screen.getByRole("button", { name: "Volver" }))

    await waitFor(() => {
      expect(
        screen.queryByText("Recordar pago pendiente", { selector: "h2" }),
      ).not.toBeInTheDocument()
    })
  })

  it("dispara router.post al confirmar y muestra estado de éxito en onSuccess", async () => {
    const user = userEvent.setup()
    postMock.mockImplementation(
      (
        _url: string,
        _data: unknown,
        options?: {
          onSuccess?: (page: unknown) => void
          onFinish?: () => void
        },
      ) => {
        options?.onSuccess?.({})
        options?.onFinish?.()
      },
    )

    render(<DebtReminderDialog {...defaultProps} />)

    await user.click(
      screen.getByRole("button", { name: "Recordar pago pendiente" }),
    )
    await user.click(
      screen.getByRole("button", { name: "Enviar recordatorio" }),
    )

    expect(postMock).toHaveBeenCalledWith(
      "/provider/collections/42/debt_reminders",
      {},
      expect.objectContaining({
        preserveScroll: true,
        preserveState: true,
      }),
    )

    expect(
      screen.getByText("Recordatorio enviado", { selector: "h2" }),
    ).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Listo" })).toBeInTheDocument()
  })

  it("muestra estado de error y botón de reintento en onError", async () => {
    const user = userEvent.setup()
    postMock.mockImplementation(
      (
        _url: string,
        _data: unknown,
        options?: {
          onError?: (errors: unknown) => void
          onFinish?: () => void
        },
      ) => {
        options?.onError?.({})
        options?.onFinish?.()
      },
    )

    render(<DebtReminderDialog {...defaultProps} />)

    await user.click(
      screen.getByRole("button", { name: "Recordar pago pendiente" }),
    )
    await user.click(
      screen.getByRole("button", { name: "Enviar recordatorio" }),
    )

    expect(
      screen.getByText("No pudimos enviar el recordatorio", { selector: "h2" }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Reintentar" }),
    ).toBeInTheDocument()
  })
})
