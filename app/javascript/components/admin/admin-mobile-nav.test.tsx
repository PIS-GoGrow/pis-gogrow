import { render, screen, within } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import { AdminMobileNav } from "./admin-mobile-nav"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    usePage: () => ({ url: "/admin/dashboard", props: {} }),
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

describe("AdminMobileNav", () => {
  function nav() {
    render(<AdminMobileNav />)
    return within(
      screen.getByRole("navigation", { name: "Navegación de RRHH" }),
    )
  }

  it("links to the sections HR can already use", () => {
    const menu = nav()

    expect(menu.getByRole("link", { name: "Inicio" })).toHaveAttribute(
      "href",
      "/admin/dashboard",
    )
    expect(menu.getByRole("link", { name: "Cuenta" })).toBeInTheDocument()
    expect(menu.getByRole("link", { name: "Empleados" })).toHaveAttribute(
      "href",
      "/admin/consumers",
    )
  })

  it("keeps the sections still to come out of reach", () => {
    const menu = nav()

    for (const name of ["Pagos"]) {
      expect(menu.queryByRole("link", { name })).not.toBeInTheDocument()
      expect(menu.getByRole("button", { name })).toHaveAttribute(
        "aria-disabled",
        "true",
      )
    }
  })

  it("marks the home as the current page", () => {
    const menu = nav()

    expect(menu.getByRole("link", { name: "Inicio" })).toHaveAttribute(
      "aria-current",
      "page",
    )
    expect(menu.getByRole("link", { name: "Cuenta" })).not.toHaveAttribute(
      "aria-current",
    )
  })
})
