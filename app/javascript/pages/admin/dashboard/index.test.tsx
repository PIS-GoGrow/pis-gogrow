import { render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import AdminDashboard from "./index"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    usePage: () => ({
      url: "/admin/dashboard",
      props: { auth: { user: { name: "Juan Pérez" } } },
    }),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

vi.mock("@/components/admin/admin-mobile-nav", () => ({
  AdminMobileNav: () => null,
}))

// Historia IBP-076: "Como RRHH, quiero visualizar una pantalla de inicio, para
// comprender qué puedo hacer con la aplicación según mi perfil."
describe("Admin Dashboard Page", () => {
  it("greets HR by first name with today's date", () => {
    render(
      <AdminDashboard today="Jueves 1 de octubre" payment_month="octubre" />,
    )

    expect(
      screen.getByRole("heading", { name: /Hola, Juan/ }),
    ).toBeInTheDocument()
    expect(screen.getByText("Jueves 1 de octubre")).toBeInTheDocument()
  })

  it("shows each section of the home as coming soon", () => {
    render(
      <AdminDashboard today="Jueves 1 de octubre" payment_month="octubre" />,
    )

    expect(screen.getByText("Tu consumo")).toBeInTheDocument()
    expect(
      screen.getByRole("region", { name: "Tus pagos de octubre" }),
    ).toHaveTextContent("Próximamente")
    expect(
      screen.getByRole("region", { name: "Ranking deuda de empleados" }),
    ).toHaveTextContent("Próximamente")
  })
})
