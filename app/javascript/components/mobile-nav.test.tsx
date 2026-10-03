import { render, screen } from "@testing-library/react"
import { Sparkles } from "lucide-react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import MobileNav from "./mobile-nav"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Link: ({
      children,
      href,
      "aria-current": ariaCurrent,
    }: {
      children: React.ReactNode
      href: string
      "aria-current"?: "page"
    }) => (
      <a href={href} aria-current={ariaCurrent}>
        {children}
      </a>
    ),
  }
})

describe("MobileNav", () => {
  it("applies custom className passed via props", () => {
    render(
      <MobileNav
        label="Navegación de prueba"
        className="custom-test-class bottom-6"
        items={[
          {
            label: "Inicio",
            icon: <Sparkles data-testid="icon" />,
            href: "/home",
            active: true,
          },
        ]}
      />,
    )

    const nav = screen.getByRole("navigation", { name: "Navegación de prueba" })
    expect(nav).toHaveClass("bottom-6")
    expect(nav).toHaveClass("custom-test-class")
  })

  it("renders disabled buttons with aria-disabled and disabled attributes for items without href", () => {
    render(
      <MobileNav
        label="Navegación de prueba"
        pendingTitle="Próximamente"
        items={[
          {
            label: "Enlace activo",
            icon: <Sparkles />,
            href: "/active",
            active: false,
          },
          {
            label: "Sección pendiente",
            icon: <Sparkles />,
            href: undefined,
            active: false,
          },
        ]}
      />,
    )

    const link = screen.getByRole("link", { name: "Enlace activo" })
    expect(link).toHaveAttribute("href", "/active")

    expect(
      screen.queryByRole("link", { name: "Sección pendiente" }),
    ).not.toBeInTheDocument()

    const button = screen.getByRole("button", { name: "Sección pendiente" })
    expect(button).toBeDisabled()
    expect(button).toHaveAttribute("aria-disabled", "true")
    expect(button).toHaveAttribute("title", "Próximamente")
  })
})
