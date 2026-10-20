import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import type { ConsumerDashboardIndex } from "@/types"

import type { CartItem, Schedule } from "./consumer-types"
import { WeeklyMenu } from "./weekly-menu"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    usePage: () => ({
      url: "/menu-semanal",
      props: {
        locale: "es",
        notifications: [],
      },
    }),
    Link: ({ children, href }: { children: React.ReactNode; href: string }) => (
      <a href={href}>{children}</a>
    ),
  }
})

const defaultBenefit: ConsumerDashboardIndex["benefit"] = {
  limit: 5,
  used: 0,
  percentage: 50,
  monthly_limit: 20,
  monthly_used: 0,
  monthly_remaining: 20,
  specials: [],
}

const sampleSchedule: Schedule = {
  id: 1,
  date: "2026-10-12",
  remaining: 10,
  sold_out: false,
  orders_closed: false,
  menu: {
    id: 101,
    name: "Milanesa con papas fritas",
    description: "Clásica milanesa de carne",
    price: 350,
    option_groups: [],
    provider_name: "Tu Viandita",
    home_delivery: true,
    reviews: [],
  },
}

const sampleCartItem: CartItem = {
  id: 1,
  cartId: "1-",
  date: "2026-10-12",
  remaining: 10,
  sold_out: false,
  orders_closed: false,
  quantity: 1,
  notes: "",
  selections: {},
  menu: sampleSchedule.menu,
}

describe("WeeklyMenu (Acceso responsive al carrito)", () => {
  function renderComponent(
    props: Partial<Parameters<typeof WeeklyMenu>[0]> = {},
  ) {
    const defaultProps = {
      name: "Juan",
      date: "2026-10-12",
      setDate: vi.fn(),
      benefit: defaultBenefit,
      providers: ["Tu Viandita"],
      schedules: [sampleSchedule],
      closures: [],
      cart: [],
      count: 0,
      total: 0,
      openDetail: vi.fn(),
      openCart: vi.fn(),
      ...props,
    }

    return {
      ...render(<WeeklyMenu {...defaultProps} />),
      props: defaultProps,
    }
  }

  it("no renderiza el botón flotante cuando el carrito está vacío", () => {
    renderComponent({ count: 0, cart: [] })

    const floatingButton = document.querySelector(
      '[data-slot="floating-cart-button"]',
    )
    expect(floatingButton).toBeNull()

    const asideCartButton = screen.getByRole("button", { name: "Ver carrito" })
    expect(asideCartButton).toBeDisabled()
  })

  it("renderiza el botón flotante con data-slot y clases responsive para mobile y tablet cuando count > 0", () => {
    renderComponent({ count: 1, total: 350, cart: [sampleCartItem] })

    const floatingButton = document.querySelector(
      '[data-slot="floating-cart-button"]',
    )
    expect(floatingButton).not.toBeNull()
    expect(floatingButton).toHaveTextContent("Ver carrito")

    // Clases verificadas: fixed, mobile bottom-24, tablet bottom md:bottom-6, oculto en desktop lg:hidden
    expect(floatingButton?.className).toContain("fixed")
    expect(floatingButton?.className).toContain("bottom-24")
    expect(floatingButton?.className).toContain("md:bottom-6")
    expect(floatingButton?.className).toContain("lg:hidden")
  })

  it("llama a openCart al presionar el botón flotante", async () => {
    const user = userEvent.setup()
    const openCart = vi.fn()
    renderComponent({ count: 2, total: 700, cart: [sampleCartItem], openCart })

    const floatingButton = document.querySelector(
      '[data-slot="floating-cart-button"]',
    )
    expect(floatingButton).not.toBeNull()

    await user.click(floatingButton!)
    expect(openCart).toHaveBeenCalledTimes(1)
  })

  it("permite abrir el carrito desde el aside de escritorio cuando count > 0", async () => {
    const user = userEvent.setup()
    const openCart = vi.fn()
    renderComponent({ count: 1, total: 350, cart: [sampleCartItem], openCart })

    const cartButtons = screen.getAllByRole("button", { name: "Ver carrito" })
    // El segundo botón es el del aside en desktop
    const asideButton = cartButtons.find(
      (btn) => btn.getAttribute("data-slot") !== "floating-cart-button",
    )
    expect(asideButton).toBeDefined()
    expect(asideButton).toBeEnabled()

    await user.click(asideButton!)
    expect(openCart).toHaveBeenCalledTimes(1)
  })

  it("muestra el resumen de viandas y monto en la tarjeta de carrito", () => {
    renderComponent({ count: 3, total: 1050, cart: [sampleCartItem] })

    expect(screen.getByText(/3 platos ·/i)).toBeInTheDocument()
  })

  it("incluye reglas de estilo css para ajustar el botón flotante al sidebar en tablets (768px a 1023px)", () => {
    const { container } = renderComponent({ count: 1, cart: [sampleCartItem] })

    const styleTag = container.querySelector("style")
    expect(styleTag).not.toBeNull()
    const cssText = styleTag?.textContent ?? ""

    expect(cssText).toContain(
      "@media (min-width: 768px) and (max-width: 1023px)",
    )
    expect(cssText).toContain('[data-slot="sidebar"][data-state="expanded"]')
    expect(cssText).toContain('[data-slot="sidebar"][data-state="collapsed"]')
    expect(cssText).toContain('[data-slot="floating-cart-button"]')
  })
})
