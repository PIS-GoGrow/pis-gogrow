import { render, screen, within } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import { AdminMobileNav } from "./admin-mobile-nav"

let currentUrl = "/admin/dashboard"

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

  it("mantiene Empleados activo al ver el detalle de un empleado", () => {
    currentUrl = "/admin/consumers/42"
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
    currentUrl = "/admin/consumers?search=juan&page=2"
    const menu = nav()

    expect(menu.getByRole("link", { name: "Empleados" })).toHaveAttribute(
      "aria-current",
      "page",
    )
  })

  it("marca Cuenta como activo en /settings/profile", () => {
    currentUrl = "/settings/profile"
    const menu = nav()

    expect(menu.getByRole("link", { name: "Cuenta" })).toHaveAttribute(
      "aria-current",
      "page",
    )
    expect(menu.getByRole("link", { name: "Inicio" })).not.toHaveAttribute(
      "aria-current",
    )
  })

  it("marca Cuenta como activo en Subsidios (/admin/benefit_configurations)", () => {
    currentUrl = "/admin/benefit_configurations"
    const menu = nav()

    expect(menu.getByRole("link", { name: "Cuenta" })).toHaveAttribute(
      "aria-current",
      "page",
    )
    expect(menu.getByRole("link", { name: "Inicio" })).not.toHaveAttribute(
      "aria-current",
    )
  })

  it("mantiene Pagos inactivo y no clickeable en facturas (/admin/invoices)", () => {
    currentUrl = "/admin/invoices"
    const menu = nav()

    expect(menu.queryByRole("link", { name: "Pagos" })).not.toBeInTheDocument()
    const pagosButton = menu.getByRole("button", { name: "Pagos" })
    expect(pagosButton).toHaveAttribute("aria-disabled", "true")
    expect(pagosButton).toBeDisabled()
    expect(pagosButton).not.toHaveAttribute("aria-current")
    expect(menu.getByRole("link", { name: "Inicio" })).not.toHaveAttribute(
      "aria-current",
    )
    expect(menu.getByRole("link", { name: "Empleados" })).not.toHaveAttribute(
      "aria-current",
    )
  })
})
