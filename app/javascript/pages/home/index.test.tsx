import { render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import Home from "./index"

vi.mock("@inertiajs/react", () => ({
  Head: ({ title }: { title?: string }) => <title>{title}</title>,
  Link: ({ children, href }: { children: React.ReactNode; href: string }) => (
    <a href={href}>{children}</a>
  ),
}))

vi.mock("@/components/branding/google-mark", () => ({
  GoogleMark: () => <span data-testid="google-mark">Google</span>,
}))

vi.mock("@/components/dev-login-form", () => ({
  default: () => <div data-testid="dev-login-form">Dev Login Form</div>,
}))

describe("Home Page Component", () => {
  it("renders consumer variant with Google mark and appropriate texts", () => {
    render(<Home variant="consumer" dev_login_enabled={false} />)

    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent(
      "Viandas GoGrow",
    )
    expect(
      screen.getByText("Tu almuerzo, sin complicaciones"),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: /Iniciar sesión con Google/i }),
    ).toBeInTheDocument()
    expect(screen.getByTestId("google-mark")).toBeInTheDocument()
    expect(screen.queryByTestId("dev-login-form")).not.toBeInTheDocument()
  })

  it("renders admin/rrhh variant with Google mark and specific texts", () => {
    render(<Home variant="admin" dev_login_enabled={false} />)

    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent(
      "Viandas GoGrow",
    )
    expect(
      screen.getByText("Simplificá las viandas de tu equipo"),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: /Continuar con Google/i }),
    ).toBeInTheDocument()
    expect(screen.getByTestId("google-mark")).toBeInTheDocument()
  })

  it("renders provider variant with feature carousel and without Google mark", () => {
    render(<Home variant="provider" dev_login_enabled={false} />)

    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent(
      "Bienvenido a Viandas GoGrow",
    )
    expect(
      screen.getByRole("region", { name: "Qué podés hacer en Viandas GoGrow" }),
    ).toBeInTheDocument()
    const providerButton = screen.getByRole("link", { name: "Unirse ahora" })
    expect(providerButton).toBeInTheDocument()
    expect(providerButton).toHaveAttribute("href", "/provider")
    expect(screen.queryByTestId("google-mark")).not.toBeInTheDocument()
  })

  it("renders DevLoginForm when dev_login_enabled is true", () => {
    render(<Home variant="consumer" dev_login_enabled={true} />)

    expect(screen.getByTestId("dev-login-form")).toBeInTheDocument()
  })
})
