import { render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import AdminPreferences from "./show"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return { ...actual, Head: () => null }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div>{children}</div>
  ),
}))

describe("Admin preferences page", () => {
  it("links only to profile and appearance", () => {
    render(<AdminPreferences />)

    expect(screen.getByRole("link", { name: /^Perfil/ })).toHaveAttribute(
      "href",
      "/settings/profile",
    )
    expect(screen.getByRole("link", { name: /^Apariencia/ })).toHaveAttribute(
      "href",
      "/settings/appearance",
    )
    expect(screen.queryByText("Contraseña")).not.toBeInTheDocument()
    expect(screen.queryByText("Eliminar cuenta")).not.toBeInTheDocument()
  })

  it("returns to the RRHH account page", () => {
    render(<AdminPreferences />)

    expect(
      screen.getByRole("link", { name: "Volver a Cuenta" }),
    ).toHaveAttribute("href", "/admin/account")
  })
})
