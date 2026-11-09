import { render, screen } from "@testing-library/react"
import type React from "react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import Profile from "./show"

let currentRole = "provider"
let formErrors: Record<string, string[]> = {}

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    usePage: () => ({
      props: {
        auth: {
          user: { name: "Proveedor Test", email: "proveedor@example.com" },
          session: { role: currentRole },
        },
      },
    }),
    Form: ({
      children,
    }: {
      children: (props: {
        errors: Record<string, string[]>
        processing: boolean
        recentlySuccessful: boolean
      }) => React.ReactNode
    }) => (
      <form>
        {children({
          errors: formErrors,
          processing: false,
          recentlySuccessful: false,
        })}
      </form>
    ),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

vi.mock("@/layouts/settings/layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="settings-layout">{children}</div>
  ),
}))

vi.mock("@/components/delete-user", () => ({
  default: () => <div data-testid="delete-user" />,
}))

describe("Settings Profiles Show Page", () => {
  beforeEach(() => {
    currentRole = "provider"
    formErrors = {}
  })

  it("shows personal, email, and password fields to providers with account navigation", () => {
    render(<Profile phone="+59899123456" />)

    expect(screen.getByLabelText("Nombre")).toHaveValue("Proveedor Test")
    expect(screen.getByLabelText("Teléfono")).toHaveValue("+59899123456")
    expect(screen.getByLabelText("Correo electrónico")).toHaveValue(
      "proveedor@example.com",
    )
    expect(screen.getByLabelText("Nueva contraseña")).toBeInTheDocument()
    expect(screen.getByText("Configuración de apariencia")).toBeInTheDocument()
    expect(
      screen.getByRole("link", { name: "Volver a Cuenta" }),
    ).toHaveAttribute("href", "/proveedor/cuenta")
    expect(screen.queryByTestId("settings-layout")).not.toBeInTheDocument()
    expect(
      screen.queryByText("Editar información de pedidos"),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByLabelText("También realizo entregas a domicilio"),
    ).not.toBeInTheDocument()
    expect(screen.queryByTestId("delete-user")).not.toBeInTheDocument()
  })

  it("shows RRHH email as read-only and hides account deletion", () => {
    currentRole = "admin"

    render(<Profile phone="+59899123456" />)

    expect(screen.getByLabelText("Correo electrónico")).toHaveValue(
      "proveedor@example.com",
    )
    expect(screen.getByLabelText("Correo electrónico")).toHaveAttribute(
      "readonly",
    )
    expect(screen.queryByTestId("delete-user")).not.toBeInTheDocument()
  })

  it("hides account deletion for consumers and shows appearance settings", () => {
    currentRole = "consumer"

    render(<Profile phone={null} />)

    expect(screen.queryByTestId("delete-user")).not.toBeInTheDocument()
    expect(screen.getByText("Configuración de apariencia")).toBeInTheDocument()
  })

  it("renders all setting sections in order for consumers as a standalone scrollable page", () => {
    currentRole = "consumer"

    render(<Profile phone="+59899123456" />)

    expect(
      screen.getByRole("link", { name: "Volver a Cuenta" }),
    ).toHaveAttribute("href", "/cuenta")
    expect(screen.queryByTestId("settings-layout")).not.toBeInTheDocument()

    // 1. Perfil
    expect(screen.getByLabelText("Nombre")).toBeInTheDocument()
    expect(screen.getByLabelText("Teléfono")).toBeInTheDocument()

    // 2. Correo electrónico
    expect(screen.getByLabelText("Correo electrónico")).toBeInTheDocument()

    // 3. Contraseña
    expect(screen.getByLabelText("Nueva contraseña")).toBeInTheDocument()
    expect(screen.getByLabelText("Confirmar contraseña")).toBeInTheDocument()

    // 4. Apariencia
    expect(screen.getByText("Configuración de apariencia")).toBeInTheDocument()

    // 5. Sin eliminar cuenta
    expect(screen.queryByTestId("delete-user")).not.toBeInTheDocument()
  })

  it("renders phone validation error message when present", () => {
    formErrors = { phone: ["El formato del celular es inválido."] }

    render(<Profile phone="2900 1234" />)

    expect(
      screen.getByText("El formato del celular es inválido."),
    ).toBeInTheDocument()
  })

  it("renders phone helper description", () => {
    render(<Profile phone="+59899123456" />)

    expect(
      screen.getByText(
        "Lo usamos para enviarte notificaciones por WhatsApp. Si tu celular no es de Uruguay, escribilo con + y el código de país.",
      ),
    ).toBeInTheDocument()
  })
})
