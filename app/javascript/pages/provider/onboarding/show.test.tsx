import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import type { SettingsNotificationConfiguration } from "@/types"
import type { ProviderOnboardingProvider } from "@/types/serializers/ProviderOnboardingProvider"

import Onboarding from "./show"

const patchMock = vi.fn()
const getMock = vi.fn()
let mockErrors: Record<string, string> = {}
let mockProcessing = false

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    Link: ({
      children,
      href,
      className,
    }: {
      children: React.ReactNode
      href: string | { url: string }
      className?: string
    }) => {
      const resolvedHref = typeof href === "string" ? href : (href?.url ?? "")
      return (
        <a href={resolvedHref} className={className}>
          {children}
        </a>
      )
    },
    router: {
      patch: (...args: unknown[]) => {
        patchMock(...args)
      },
      get: (...args: unknown[]) => {
        getMock(...args)
      },
    },
    Form: ({
      children,
      className,
    }: {
      children: (props: {
        errors: Record<string, string>
        processing: boolean
      }) => React.ReactNode
      className?: string
    }) => (
      <form className={className}>
        {children({
          errors: mockErrors,
          processing: mockProcessing,
        })}
      </form>
    ),
  }
})

const defaultProvider: ProviderOnboardingProvider = {
  bank_name: "BROU",
  bank_account_type: "savings",
  bank_account_number: "001234567-00001",
  bank_account_holder: "Tu Vianda SRL",
  tax_id: "212345670012",
  home_delivery: true,
  order_deadline: "12:00",
}

const mockConfigurations: SettingsNotificationConfiguration[] = [
  {
    id: 10,
    key: "order_created",
    title: "Pedidos nuevos",
    description:
      "Recibí una notificación cuando un empleado te haga un pedido.",
  },
  {
    id: 20,
    key: "payment_receipt_uploaded",
    title: "Comprobantes de pago",
    description:
      "Recibí una notificación cuando te envíen un comprobante de pago.",
  },
]

function renderPage(
  step: string,
  overrides: Partial<ProviderOnboardingProvider> = {},
) {
  return render(
    <Onboarding
      provider={{ ...defaultProvider, ...overrides }}
      step={step}
      notification_configurations={mockConfigurations}
      subscribed_keys={["order_created"] as unknown as [string]}
    />,
  )
}

describe("Provider Onboarding Show Page", () => {
  const user = userEvent.setup()

  beforeEach(() => {
    patchMock.mockClear()
    getMock.mockClear()
    mockErrors = {}
    mockProcessing = false
  })

  describe("Paso 1: Datos de cobro", () => {
    it("muestra los campos de cobro y el progreso del paso 1", () => {
      renderPage("1")

      expect(screen.getByText("Paso 1 de 4")).toBeInTheDocument()
      expect(screen.getByText("Datos de cobro")).toBeInTheDocument()
      expect(screen.getByLabelText("Banco")).toHaveValue("BROU")
      expect(screen.getByLabelText("Número de cuenta")).toHaveValue(
        "001234567-00001",
      )
      expect(screen.getByLabelText("Titular de la cuenta")).toHaveValue(
        "Tu Vianda SRL",
      )
      expect(screen.getByLabelText("RUT o CI del titular")).toHaveValue(
        "212345670012",
      )
      expect(
        screen.queryByLabelText("Volver al paso anterior"),
      ).not.toBeInTheDocument()
      expect(
        screen.getByRole("button", { name: "Continuar" }),
      ).toBeInTheDocument()
      expect(
        screen.getAllByRole("button", { name: "Omitir por ahora" }),
      ).toHaveLength(2)
    })

    it("muestra errores de validación en los campos cuando el servidor los devuelve", () => {
      mockErrors = {
        bank_name: "El banco no puede estar en blanco",
        tax_id: "El RUT debe tener 12 dígitos",
      }

      renderPage("1")

      expect(
        screen.getByText("El banco no puede estar en blanco"),
      ).toBeInTheDocument()
      expect(
        screen.getByText("El RUT debe tener 12 dígitos"),
      ).toBeInTheDocument()
    })
  })

  describe("Paso 2: Hora de cierre", () => {
    it("muestra el campo de hora de cierre y el botón de volver", () => {
      renderPage("2")

      expect(screen.getByText("Paso 2 de 4")).toBeInTheDocument()
      expect(screen.getByLabelText("Hora de cierre")).toHaveValue("12:00")
      expect(
        screen.getByLabelText("Volver al paso anterior"),
      ).toBeInTheDocument()
    })

    it("permite volver al paso anterior haciendo clic en el botón de atrás", async () => {
      renderPage("2")

      const backButton = screen.getByLabelText("Volver al paso anterior")
      await user.click(backButton)

      expect(getMock).toHaveBeenCalledWith(
        "/provider/primeros-pasos",
        { step: 1 },
        { preserveScroll: true },
      )
    })
  })

  describe("Paso 3: Entregas", () => {
    it("muestra la opción de entregas personalizadas con su switch", () => {
      renderPage("3", { home_delivery: true })

      expect(screen.getByText("Paso 3 de 4")).toBeInTheDocument()
      expect(screen.getByText("Direcciones personalizadas")).toBeInTheDocument()
      expect(screen.getByRole("switch")).toBeChecked()
    })

    it("envía el cambio de modalidad de entrega al continuar", async () => {
      renderPage("3", { home_delivery: true })

      const toggle = screen.getByRole("switch")
      await user.click(toggle)
      expect(toggle).not.toBeChecked()

      const continueBtn = screen.getByRole("button", { name: "Continuar" })
      await user.click(continueBtn)

      expect(patchMock).toHaveBeenCalledWith(
        "/provider/primeros-pasos",
        { step: 3, commit: "continue", home_delivery: false },
        expect.objectContaining({ preserveScroll: true }),
      )
    })
  })

  describe("Paso 4: Notificaciones", () => {
    it("muestra las alertas disponibles y el estado inicial de suscripción", () => {
      renderPage("4")

      expect(screen.getByText("Paso 4 de 4")).toBeInTheDocument()
      expect(screen.getByText("Notificaciones")).toBeInTheDocument()
      expect(screen.getByText("Pedidos nuevos")).toBeInTheDocument()
      expect(screen.getByText("Comprobantes de pago")).toBeInTheDocument()

      const switches = screen.getAllByRole("switch")
      expect(switches[0]).toBeChecked() // order_created
      expect(switches[1]).not.toBeChecked() // payment_receipt_uploaded
      expect(
        screen.getByRole("button", { name: "Finalizar" }),
      ).toBeInTheDocument()
    })

    it("envía las IDs suscritas al finalizar el paso 4", async () => {
      renderPage("4")

      const switches = screen.getAllByRole("switch")
      await user.click(switches[1]) // activate payment_receipt_uploaded

      const finishBtn = screen.getByRole("button", { name: "Finalizar" })
      await user.click(finishBtn)

      expect(patchMock).toHaveBeenCalledWith(
        "/provider/primeros-pasos",
        { step: 4, commit: "continue", subscribed_ids: [10, 20] },
        expect.objectContaining({ preserveScroll: true }),
      )
    })
  })

  describe("Paso 'done': Pantalla final", () => {
    it("muestra el mensaje de éxito y el botón de redirección al panel", () => {
      renderPage("done")

      expect(screen.getByText("¡Todo listo!")).toBeInTheDocument()
      expect(
        screen.getByText(
          "Tu cuenta ya está configurada y podés empezar a recibir pedidos.",
        ),
      ).toBeInTheDocument()

      const ctaLink = screen.getByRole("link", { name: "Ir al Inicio" })
      expect(ctaLink).toBeInTheDocument()
      expect(ctaLink).toHaveAttribute("href", "/provider/inicio")
    })
  })

  describe("Control de omitir paso", () => {
    it("envía commit: 'skip' con el paso actual al hacer clic en Omitir por ahora", async () => {
      renderPage("1")

      const skipButtons = screen.getAllByRole("button", {
        name: "Omitir por ahora",
      })
      await user.click(skipButtons[1]) // footer button

      expect(patchMock).toHaveBeenCalledWith(
        "/provider/primeros-pasos",
        { step: 1, commit: "skip" },
        { preserveScroll: true },
      )
    })
  })
})
