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

const summary = { total: 50, base: 50, specials: [] }

// Historia: "Como EMPLEADO, quiero consultar la información de mi cuenta,
// incluyendo nombre, email corporativo, foto de perfil y beneficio asignado,
// para disponer de mi información personal y poder cerrar sesión."
describe("Consumer account page", () => {
  // El Avatar solo monta la imagen cuando el navegador la carga, cosa que jsdom
  // no hace, así que acá se verifica el respaldo con las iniciales.
  it("shows the name, the corporate email and the profile photo", () => {
    render(<Show benefit={benefit} benefit_summary={summary} />)

    expect(screen.getByText("Juan Pérez")).toBeInTheDocument()
    expect(screen.getByText("juan@gogrow.com")).toBeInTheDocument()
    expect(screen.getByText("JP")).toBeInTheDocument()
  })

  it("shows the assigned benefit", () => {
    render(<Show benefit={benefit} benefit_summary={summary} />)

    expect(screen.getByText("Activo")).toBeInTheDocument()
    expect(screen.getAllByText("50%")).toHaveLength(2)
    expect(screen.getByText("20 viandas")).toBeInTheDocument()
    expect(screen.getByText("13 viandas")).toBeInTheDocument()
    expect(screen.getByText("31/10/2026")).toBeInTheDocument()
  })

  // Criterio: sin beneficio asignado se explica, en vez de mostrar ceros que
  // parecerían un beneficio agotado.
  it("explains that there is no benefit instead of showing zeroes", () => {
    render(<Show benefit={null} benefit_summary={null} />)

    expect(
      screen.getByText(/Todavía no tenés un beneficio/),
    ).toBeInTheDocument()
    expect(screen.queryByText("0 viandas")).not.toBeInTheDocument()
  })

  // IBP-037, Figma: el total combinado en grande y el desglose del base y de
  // cada subsidio especial vigente con el nombre que le puso RRHH.
  it("adds the special subsidies to the base one and breaks them down", () => {
    render(
      <Show
        benefit={benefit}
        benefit_summary={{
          total: 75,
          base: 50,
          specials: [{ name: "Antigüedad (5 años)", percentage: 25 }],
        }}
      />,
    )

    expect(screen.getByText("Mi beneficio")).toBeInTheDocument()
    expect(screen.getByText("75%")).toBeInTheDocument()
    expect(screen.getByText("de descuento en viandas")).toBeInTheDocument()
    expect(screen.getByText("Subsidio Base").nextSibling).toHaveTextContent(
      "50%",
    )
    expect(
      screen.getByText("Antigüedad (5 años)").nextSibling,
    ).toHaveTextContent("25%")
    expect(screen.getByText("20 viandas")).toBeInTheDocument()
  })

  it("offers signing out", () => {
    render(<Show benefit={benefit} benefit_summary={summary} />)

    expect(screen.getByRole("button", { name: /Salir/ })).toBeInTheDocument()
  })
})
