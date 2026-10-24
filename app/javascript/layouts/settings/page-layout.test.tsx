import { render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import SettingsPageLayout from "./page-layout"

let role = "admin"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    usePage: () => ({ props: { auth: { session: { role } } } }),
  }
})

vi.mock("@/layouts/settings/layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="settings-sidebar-layout">{children}</div>
  ),
}))

describe("SettingsPageLayout", () => {
  it("renders RRHH settings as a standalone page with account navigation", () => {
    role = "admin"

    render(
      <SettingsPageLayout
        title="Notificaciones"
        description="Configurá qué alertas querés recibir"
        adminBackLabel="Volver a Cuenta"
      >
        <div>Opciones</div>
      </SettingsPageLayout>,
    )

    expect(
      screen.queryByTestId("settings-sidebar-layout"),
    ).not.toBeInTheDocument()
    expect(
      screen.getByRole("link", { name: "Volver a Cuenta" }),
    ).toHaveAttribute("href", "/rrhh/cuenta")
  })

  it("renders provider settings as a standalone page with account navigation", () => {
    role = "provider"

    render(
      <SettingsPageLayout
        title="Notificaciones"
        description="Configurá qué alertas querés recibir"
      >
        <div>Opciones</div>
      </SettingsPageLayout>,
    )

    expect(
      screen.queryByTestId("settings-sidebar-layout"),
    ).not.toBeInTheDocument()
    expect(
      screen.getByRole("link", { name: "Volver a Cuenta" }),
    ).toHaveAttribute("href", "/proveedor/cuenta")
  })

  it("preserves the settings sidebar for employees", () => {
    role = "consumer"

    render(
      <SettingsPageLayout
        title="Notificaciones"
        description="Configurá qué alertas querés recibir"
      >
        <div>Opciones</div>
      </SettingsPageLayout>,
    )

    expect(screen.getByTestId("settings-sidebar-layout")).toBeInTheDocument()
  })
})
