import { render, screen, within } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import { AdminMobileNav } from "./admin-mobile-nav"

let currentUrl = "/admin/inicio"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    usePage: () => ({ url: currentUrl, props: {} }),
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
      screen.getByRole("navigation", { name: "Navegación de RR. HH." }),
    )
  }

  it("links to the sections HR can already use", () => {
    const menu = nav()

    expect(menu.getByRole("link", { name: "Inicio" })).toHaveAttribute(
      "href",
      "/admin/inicio",
    )
    expect(menu.getByRole("link", { name: "Cuenta" })).toBeInTheDocument()
    expect(menu.getByRole("link", { name: "Cuenta" })).toHaveAttribute(
      "href",
      "/admin/cuenta",
    )
    expect(menu.getByRole("link", { name: "Empleados" })).toHaveAttribute(
      "href",
      "/admin/empleados",
    )
  })

  it("shows Pagos as an accessible navigation link", () => {
    const menu = nav()

    expect(menu.getByRole("link", { name: "Pagos" })).toHaveAttribute(
      "href",
      "/admin/pagos",
    )
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

  it("mantiene Empleados activo al ver el detalle de un empleado", () => {
    currentUrl = "/admin/empleados/42"
    const menu = nav()

    expect(menu.getByRole("link", { name: "Empleados" })).toHaveAttribute(
      "aria-current",
      "page",
    )
    expect(menu.getByRole("link", { name: "Inicio" })).not.toHaveAttribute(
      "aria-current",
    )
  })

  it("mantiene Empleados activo cuando la URL contiene parámetros de búsqueda", () => {
    currentUrl = "/admin/empleados?search=juan&page=2"
    const menu = nav()

    expect(menu.getByRole("link", { name: "Empleados" })).toHaveAttribute(
      "aria-current",
      "page",
    )
  })

  it("marca Cuenta como activo en /configuracion/perfil", () => {
    currentUrl = "/configuracion/perfil"
    const menu = nav()

    expect(menu.getByRole("link", { name: "Cuenta" })).toHaveAttribute(
      "aria-current",
      "page",
    )
    expect(menu.getByRole("link", { name: "Inicio" })).not.toHaveAttribute(
      "aria-current",
    )
  })

  it("marca Cuenta como activo en /admin/cuenta", () => {
    currentUrl = "/admin/cuenta"
    const menu = nav()

    expect(menu.getByRole("link", { name: "Cuenta" })).toHaveAttribute(
      "aria-current",
      "page",
    )
  })

  it("marca Cuenta como activo en /admin/preferencias", () => {
    currentUrl = "/admin/preferencias"
    const menu = nav()

    expect(menu.getByRole("link", { name: "Cuenta" })).toHaveAttribute(
      "aria-current",
      "page",
    )
  })

  it("marca Cuenta como activo en Subsidios (/admin/subsidios)", () => {
    currentUrl = "/admin/subsidios"
    const menu = nav()

    expect(menu.getByRole("link", { name: "Cuenta" })).toHaveAttribute(
      "aria-current",
      "page",
    )
    expect(menu.getByRole("link", { name: "Inicio" })).not.toHaveAttribute(
      "aria-current",
    )
  })

  it("mantiene Pagos inactivo en facturas (/admin/facturas)", () => {
    currentUrl = "/admin/facturas"
    const menu = nav()

    const pagosLink = menu.getByRole("link", { name: "Pagos" })
    expect(pagosLink).not.toHaveAttribute("aria-current")
    expect(menu.getByRole("link", { name: "Inicio" })).not.toHaveAttribute(
      "aria-current",
    )
    expect(menu.getByRole("link", { name: "Empleados" })).not.toHaveAttribute(
      "aria-current",
    )
  })
})
