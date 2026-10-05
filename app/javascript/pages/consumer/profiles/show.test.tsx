import { render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import Show from "./show"

const auth = {
  user: {
    name: "Juan Pérez",
    email: "juan@gogrow.com",
    avatar: "https://example.com/juan.png",
  },
  session: { id: 1 },
}

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    router: { flushAll: vi.fn() },
    usePage: () => ({ props: { auth, locale: "es" } }),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

const benefit = {
  percentage: 50,
  monthly_limit: 20,
  monthly_remaining: 13,
  max_price: 500,
  due_date: "31/10/2026",
}

// Historia: "Como EMPLEADO, quiero consultar la información de mi cuenta,
// incluyendo nombre, email corporativo, foto de perfil y beneficio asignado,
// para disponer de mi información personal y poder cerrar sesión."
describe("Consumer account page", () => {
  // El Avatar solo monta la imagen cuando el navegador la carga, cosa que jsdom
  // no hace, así que acá se verifica el respaldo con las iniciales.
  it("shows the name, the corporate email and the profile photo", () => {
    render(<Show benefit={benefit} />)

    expect(screen.getByText("Juan Pérez")).toBeInTheDocument()
    expect(screen.getByText("juan@gogrow.com")).toBeInTheDocument()
    expect(screen.getByText("JP")).toBeInTheDocument()
  })

  it("shows the assigned benefit", () => {
    render(<Show benefit={benefit} />)

    expect(screen.getByText("50 %")).toBeInTheDocument()
    expect(screen.getByText("20 viandas")).toBeInTheDocument()
    expect(screen.getByText("13 viandas")).toBeInTheDocument()
    expect(screen.getByText("31/10/2026")).toBeInTheDocument()
  })

  // Criterio: sin beneficio asignado se explica, en vez de mostrar ceros que
  // parecerían un beneficio agotado.
  it("explains that there is no benefit instead of showing zeroes", () => {
    render(<Show benefit={null} />)

    expect(
      screen.getByText(/Todavía no tenés un beneficio/),
    ).toBeInTheDocument()
    expect(screen.queryByText("0 viandas")).not.toBeInTheDocument()
  })

  it("offers signing out", () => {
    render(<Show benefit={benefit} />)

    expect(screen.getByRole("button", { name: /Salir/ })).toBeInTheDocument()
  })
})
