import { render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import ProviderWelcome from "./show"

vi.mock("@inertiajs/react", () => ({
  Head: ({ title }: { title?: string }) => <title>{title}</title>,
  Link: ({ children, href }: { children: React.ReactNode; href: string }) => (
    <a href={href}>{children}</a>
  ),
}))

describe("ProviderWelcome", () => {
  it("greets the provider, names the company and links to the registration", () => {
    render(
      <ProviderWelcome
        username="Ana"
        company_name="GoGrow"
        invitation_path="/proveedor/invitacion?token=1.abc"
      />,
    )

    expect(screen.getByRole("heading", { level: 1 })).toHaveTextContent(
      "Bienvenido a Viandas GoGrow",
    )
    expect(
      screen.getByText(
        "¡Hola Ana! GoGrow te invitó a unirte como proveedor de viandas.",
      ),
    ).toBeInTheDocument()
    expect(screen.getByRole("link", { name: "Unirse ahora" })).toHaveAttribute(
      "href",
      "/proveedor/invitacion?token=1.abc",
    )
  })
})
