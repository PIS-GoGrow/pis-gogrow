import { render, screen, within } from "@testing-library/react"
import type React from "react"
import { afterEach, describe, expect, it, vi } from "vitest"

import { ProviderMobileNav } from "./provider-mobile-nav"

const page = vi.hoisted(() => ({
  url: "/proveedor/inicio",
  component: "provider/dashboard/index",
}))

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    usePage: () => ({ ...page, props: {} }),
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

describe("ProviderMobileNav", () => {
  afterEach(() => {
    page.url = "/proveedor/inicio"
    page.component = "provider/dashboard/index"
  })

  function nav() {
    render(<ProviderMobileNav />)
    return within(
      screen.getByRole("navigation", { name: "Navegación del proveedor" }),
    )
  }

  it("ofrece enlaces a todas las secciones operativas del proveedor", () => {
    const menu = nav()

    expect(menu.getByRole("link", { name: "Inicio" })).toHaveAttribute(
      "href",
      "/proveedor/inicio",
    )
    expect(menu.getByRole("link", { name: "Menú" })).toHaveAttribute(
      "href",
      "/publicar-menu",
    )
    expect(menu.getByRole("link", { name: "Pedidos" })).toHaveAttribute(
      "href",
      "/proveedor/pedidos",
    )
    expect(menu.getByRole("link", { name: "Cobros" })).toHaveAttribute(
      "href",
      "/proveedor/cobros",
    )
    expect(menu.getByRole("link", { name: "Cuenta" })).toHaveAttribute(
      "href",
      "/proveedor/cuenta",
    )
  })

  it("marca la página de inicio como la página actual activa", () => {
    const menu = nav()

    expect(menu.getByRole("link", { name: "Inicio" })).toHaveAttribute(
      "aria-current",
      "page",
    )
    expect(menu.getByRole("link", { name: "Pedidos" })).not.toHaveAttribute(
      "aria-current",
    )
  })

  it("marca Inicio como la página actual en Hallazgos", () => {
    page.url = "/proveedor/inicio/hallazgos?period=2026-09"
    page.component = "provider/insights/index"

    const menu = nav()

    expect(menu.getByRole("link", { name: "Inicio" })).toHaveAttribute(
      "aria-current",
      "page",
    )
  })

  it("marca Menú como la página actual al editar un plato", () => {
    page.url = "/proveedor/platos/1/editar"
    page.component = "provider/menus/edit"

    const menu = nav()

    expect(menu.getByRole("link", { name: "Menú" })).toHaveAttribute(
      "aria-current",
      "page",
    )
  })

  it("marca Cuenta como la página actual en Entregas", () => {
    page.url = "/proveedor/entregas"
    page.component = "provider/deliveries/show"

    const menu = nav()

    expect(menu.getByRole("link", { name: "Cuenta" })).toHaveAttribute(
      "aria-current",
      "page",
    )
  })
})
