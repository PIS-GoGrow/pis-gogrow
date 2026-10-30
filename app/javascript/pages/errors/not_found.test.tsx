import { render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import NotFound from "./not_found"

let mockUrl = "/menu-semanal"
let mockAuth: { session: { role: string } | null } = {
  session: { role: "consumer" },
}

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: ({ title }: { title?: string }) => <title>{title}</title>,
    Link: ({
      children,
      href,
    }: {
      children: React.ReactNode
      href: string | { url: string }
    }) => {
      const targetUrl = typeof href === "string" ? href : href.url
      return <a href={targetUrl}>{children}</a>
    },
    usePage: () => ({
      url: mockUrl,
      props: {
        auth: mockAuth,
      },
    }),
  }
})

describe("NotFound Error Page", () => {
  it("renders provider area with active provider session and links to provider panel", () => {
    mockUrl = "/proveedor/platos/999/editar"
    mockAuth = { session: { role: "provider" } }

    render(<NotFound />)

    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent(
      "¡Ups! Esta página no existe",
    )
    expect(
      screen.getByText(
        "La dirección que buscás no está disponible o fue movida.",
      ),
    ).toBeInTheDocument()

    const panelLink = screen.getByRole("link", { name: "Ir a mi panel" })
    expect(panelLink).toHaveAttribute("href", "/proveedor/inicio")

    const homeLink = screen.getByRole("link", { name: "Volver al inicio" })
    expect(homeLink).toHaveAttribute("href", "/proveedor/inicio")
  })

  it("renders provider area without session and links to provider login", () => {
    mockUrl = "/proveedor/facturas/invalido/archivo"
    mockAuth = { session: null }

    render(<NotFound />)

    const signInLink = screen.getByRole("link", { name: "Iniciar sesión" })
    expect(signInLink).toHaveAttribute("href", "/proveedor")

    const homeLink = screen.getByRole("link", { name: "Volver al inicio" })
    expect(homeLink).toHaveAttribute("href", "/proveedor")
  })

  it("renders consumer session outside provider area linking to weekly menu and home", () => {
    mockUrl = "/platos/999"
    mockAuth = { session: { role: "consumer" } }

    render(<NotFound />)

    const menuLink = screen.getByRole("link", { name: "Ir a mi menú" })
    expect(menuLink).toHaveAttribute("href", "/menu-semanal")

    const homeLink = screen.getByRole("link", { name: "Volver al inicio" })
    expect(homeLink).toHaveAttribute("href", "/")
  })

  it("renders admin session outside provider area linking to admin panel and home", () => {
    mockUrl = "/rrhh/recurso-inexistente"
    mockAuth = { session: { role: "admin" } }

    render(<NotFound />)

    const panelLink = screen.getByRole("link", { name: "Ir a mi panel" })
    expect(panelLink).toHaveAttribute("href", "/rrhh/inicio")

    const homeLink = screen.getByRole("link", { name: "Volver al inicio" })
    expect(homeLink).toHaveAttribute("href", "/")
  })

  it("renders unauthenticated user outside provider area linking to session login and home", () => {
    mockUrl = "/ruta-inexistente"
    mockAuth = { session: null }

    render(<NotFound />)

    const signInLink = screen.getByRole("link", { name: "Iniciar sesión" })
    expect(signInLink).toHaveAttribute("href", "/consumidor")

    const homeLink = screen.getByRole("link", { name: "Volver al inicio" })
    expect(homeLink).toHaveAttribute("href", "/")
  })
})
