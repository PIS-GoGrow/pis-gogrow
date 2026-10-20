import { render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import AdminAccount from "./show"

const auth = {
  user: {
    name: "Florencia Pérez",
    email: "florencia@gogrow.dev",
    avatar: "https://example.com/florencia.png",
  },
  session: { id: 7, role: "admin" },
}

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    router: { flushAll: vi.fn() },
    usePage: () => ({ props: { auth, locale: "es" } }),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

describe("Admin account page", () => {
  it("shows the authenticated administrator", () => {
    render(<AdminAccount />)

    expect(screen.getByText("Florencia Pérez")).toBeInTheDocument()
    expect(screen.getByText("florencia@gogrow.dev")).toBeInTheDocument()
    expect(screen.getByText("FP")).toBeInTheDocument()
  })

  it("links to subsidies and notification settings", () => {
    render(<AdminAccount />)

    expect(screen.getByRole("link", { name: /Subsidios/ })).toHaveAttribute(
      "href",
      "/admin/subsidios",
    )
    expect(
      screen.getByRole("link", { name: /Notificaciones/ }),
    ).toHaveAttribute("href", "/configuracion/notificaciones")
  })

  it("links to profile and appearance without security options", () => {
    render(<AdminAccount />)

    expect(
      screen.getByRole("link", { name: /^Perfil y Apariencia/ }),
    ).toHaveAttribute("href", "/admin/preferencias")
    expect(screen.queryByText("Seguridad")).not.toBeInTheDocument()
    expect(screen.queryByText("Cambiar contraseña")).not.toBeInTheDocument()
    expect(screen.queryByText("Eliminar cuenta")).not.toBeInTheDocument()
  })

  it("offers signing out", () => {
    render(<AdminAccount />)

    expect(screen.getByRole("button", { name: /Salir/ })).toBeInTheDocument()
  })
})
