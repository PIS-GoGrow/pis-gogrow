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
      "/rrhh/subsidios",
    )
    expect(
      screen.getByRole("link", { name: /Notificaciones/ }),
    ).toHaveAttribute("href", "/configuracion/notificaciones")
  })

  it("links to invoices", () => {
    render(<AdminAccount />)

    expect(screen.getByRole("link", { name: /^Facturas/ })).toHaveAttribute(
      "href",
      "/rrhh/facturas",
    )
    expect(
      screen.getByText("Consultá las facturas de los proveedores"),
    ).toBeInTheDocument()
  })

  it("places invoices between subsidies and order events in navigation items", () => {
    render(<AdminAccount />)

    const links = screen.getAllByRole("link")
    const hrefs = links.map((link) => link.getAttribute("href"))
    const subsidiesIndex = hrefs.indexOf("/rrhh/subsidios")
    const invoicesIndex = hrefs.indexOf("/rrhh/facturas")
    const orderEventsIndex = hrefs.indexOf("/rrhh/auditoria")

    expect(subsidiesIndex).toBeGreaterThanOrEqual(0)
    expect(invoicesIndex).toBeGreaterThan(subsidiesIndex)
    expect(orderEventsIndex).toBeGreaterThan(invoicesIndex)
  })

  it("links to profile and appearance without security options", () => {
    render(<AdminAccount />)

    expect(
      screen.getByRole("link", { name: /^Perfil y Apariencia/ }),
    ).toHaveAttribute("href", "/rrhh/preferencias")
    expect(screen.queryByText("Seguridad")).not.toBeInTheDocument()
    expect(screen.queryByText("Cambiar contraseña")).not.toBeInTheDocument()
    expect(screen.queryByText("Eliminar cuenta")).not.toBeInTheDocument()
  })

  it("offers signing out", () => {
    render(<AdminAccount />)

    expect(screen.getByRole("button", { name: /Salir/ })).toBeInTheDocument()
  })
})
