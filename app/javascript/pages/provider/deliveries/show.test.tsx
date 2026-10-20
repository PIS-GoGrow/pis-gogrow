import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import Deliveries from "./show"

const patchMock = vi.fn()

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    Link: ({
      children,
      "aria-label": ariaLabel,
    }: {
      children: React.ReactNode
      "aria-label"?: string
    }) => (
      <a href="#" aria-label={ariaLabel}>
        {children}
      </a>
    ),
    router: {
      patch: (...args: unknown[]) => {
        patchMock(...args)
      },
    },
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div>{children}</div>
  ),
}))

const renderPage = (homeDelivery: boolean) =>
  render(
    <Deliveries
      provider={{ id: 1, name: "Tu Viandita", home_delivery: homeDelivery }}
    />,
  )

describe("Provider Deliveries Show Page", () => {
  const user = userEvent.setup()

  beforeEach(() => {
    patchMock.mockClear()
  })

  it("shows both delivery options with their descriptions", () => {
    renderPage(true)

    expect(screen.getByText("Entregas")).toBeInTheDocument()
    expect(
      screen.getByText(
        "Elegí dónde realizás tus entregas y si aceptás direcciones personalizadas.",
      ),
    ).toBeInTheDocument()
    expect(
      screen.getByText(
        "Entregás todos los pedidos en las oficinas de las empresas.",
      ),
    ).toBeInTheDocument()
    expect(
      screen.getByText(
        "También aceptás pedidos con direcciones de entrega personalizadas.",
      ),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("link", { name: "Volver a Cuenta" }),
    ).toBeInTheDocument()
  })

  it("selects offices and custom addresses when home delivery is on", () => {
    renderPage(true)

    expect(
      screen.getByRole("radio", {
        name: /Oficinas y direcciones personalizadas/,
      }),
    ).toBeChecked()
    expect(
      screen.getByRole("radio", { name: /Solo Oficinas/ }),
    ).not.toBeChecked()
  })

  it("selects office only when home delivery is off", () => {
    renderPage(false)

    expect(screen.getByRole("radio", { name: /Solo Oficinas/ })).toBeChecked()
  })

  it("saves office only as soon as it is selected", async () => {
    renderPage(true)

    await user.click(screen.getByRole("radio", { name: /Solo Oficinas/ }))

    expect(patchMock).toHaveBeenCalledTimes(1)
    expect(patchMock).toHaveBeenCalledWith(
      "/provider/entregas",
      { home_delivery: false },
      expect.objectContaining({ preserveScroll: true }),
    )
  })

  it("disables the options while saving", async () => {
    renderPage(false)

    await user.click(
      screen.getByRole("radio", {
        name: /Oficinas y direcciones personalizadas/,
      }),
    )

    expect(patchMock).toHaveBeenCalledWith(
      "/provider/entregas",
      { home_delivery: true },
      expect.anything(),
    )
    for (const radio of screen.getAllByRole("radio")) {
      expect(radio).toBeDisabled()
    }
  })
})
