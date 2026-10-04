import { render, screen, within } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import { ProviderMobileNav } from "./provider-mobile-nav"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    usePage: () => ({ url: "/provider/dashboard", props: {} }),
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
      "/provider/dashboard",
    )
    expect(menu.getByRole("link", { name: "Menú" })).toHaveAttribute(
      "href",
      "/schedules",
    )
    expect(menu.getByRole("link", { name: "Pedidos" })).toHaveAttribute(
      "href",
      "/provider/orders",
    )
    expect(menu.getByRole("link", { name: "Cobros" })).toHaveAttribute(
      "href",
      "/provider/collections",
    )
    expect(menu.getByRole("link", { name: "Cuenta" })).toHaveAttribute(
      "href",
      "/provider/account",
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
})
