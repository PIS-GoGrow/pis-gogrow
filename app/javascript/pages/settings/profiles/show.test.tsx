import { render, screen } from "@testing-library/react"
import type React from "react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import Profile from "./show"

let currentRole = "provider"

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
          errors: {},
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
  })

  it("shows only personal fields and account navigation to providers", () => {
    render(<Profile phone="+59899123456" />)

    expect(screen.getByLabelText("Nombre")).toHaveValue("Proveedor Test")
    expect(screen.getByLabelText("Teléfono")).toHaveValue("+59899123456")
    expect(screen.getByRole("button", { name: "Guardar" })).toBeInTheDocument()
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

  it("preserves account deletion for consumers", () => {
    currentRole = "consumer"

    render(<Profile phone={null} />)

    expect(screen.getByTestId("delete-user")).toBeInTheDocument()
  })
})
