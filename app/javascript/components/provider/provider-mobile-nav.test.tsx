import { render, screen, within } from "@testing-library/react"
import type React from "react"
import { afterEach, describe, expect, it, vi } from "vitest"

import { ProviderMobileNav } from "./provider-mobile-nav"

const page = vi.hoisted(() => ({
  url: "/provider/inicio",
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
    page.url = "/provider/inicio"
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
      "/provider/inicio",
    )
    expect(menu.getByRole("link", { name: "Menú" })).toHaveAttribute(
      "href",
      "/publicar-menu",
    )
    expect(menu.getByRole("link", { name: "Pedidos" })).toHaveAttribute(
      "href",
      "/provider/pedidos",
    )
    expect(menu.getByRole("link", { name: "Cobros" })).toHaveAttribute(
      "href",
      "/provider/cobros",
    )
    expect(menu.getByRole("link", { name: "Cuenta" })).toHaveAttribute(
      "href",
      "/provider/cuenta",
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

  it("marca Menú como la página actual al editar un plato", () => {
    page.url = "/provider/platos/1/editar"
    page.component = "provider/menus/edit"

    const menu = nav()

    expect(menu.getByRole("link", { name: "Menú" })).toHaveAttribute(
      "aria-current",
      "page",
    )
  })

  it("marca Cuenta como la página actual en Entregas", () => {
    page.url = "/provider/entregas"
    page.component = "provider/deliveries/show"

    const menu = nav()

    expect(menu.getByRole("link", { name: "Cuenta" })).toHaveAttribute(
      "aria-current",
      "page",
    )
  })
})
