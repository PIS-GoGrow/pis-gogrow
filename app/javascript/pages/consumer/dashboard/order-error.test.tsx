import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import { OrderError } from "./order-error"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Link: ({
      children,
      href,
      ...props
    }: {
      children: React.ReactNode
      href: string | { url: string }
      preserveState?: boolean
    }) => {
      delete props.preserveState
      return (
        <a href={typeof href === "string" ? href : href.url} {...props}>
          {children}
        </a>
      )
    },
  }
})

describe("OrderError Component", () => {
  const defaultProps = {
    retry: vi.fn(),
    homeUrl: "/dashboard",
  }

  it("renderiza el título de error y el icono dentro de la tarjeta", () => {
    render(<OrderError {...defaultProps} />)

    expect(
      screen.getByRole("heading", { name: "No se pudo procesar el pedido" }),
    ).toBeInTheDocument()
  })

  it("muestra el mensaje de error predeterminado cuando no se provee la prop error", () => {
    render(<OrderError {...defaultProps} />)

    expect(
      screen.getByText(
        "Hubo un problema al procesar tu pedido. Intentá de nuevo.",
      ),
    ).toBeInTheDocument()
  })

  it("muestra el mensaje de error específico cuando se proporciona", () => {
    const customError = "El plato seleccionado se quedó sin stock disponible."
    render(<OrderError {...defaultProps} error={customError} />)

    expect(screen.getByText(customError)).toBeInTheDocument()
    expect(
      screen.queryByText(
        "Hubo un problema al procesar tu pedido. Intentá de nuevo.",
      ),
    ).not.toBeInTheDocument()
  })

  it("aplica flex-1 en ambos botones para que compartan el ancho sin desbordar el contenedor", () => {
    render(<OrderError {...defaultProps} />)

    const retryButton = screen.getByRole("button", { name: "Reintentar" })
    const homeLinkButton = screen.getByRole("link", { name: "Volver a Menú" })

    // Ambos botones deben tener flex-1 y no w-full
    expect(retryButton).toHaveClass("flex-1")
    expect(retryButton).not.toHaveClass("w-full")

    expect(homeLinkButton).toHaveClass("flex-1")
    expect(homeLinkButton).not.toHaveClass("w-full")
  })

  it("invoca la función retry al presionar el botón Reintentar", async () => {
    const user = userEvent.setup()
    const retryMock = vi.fn()
    render(<OrderError {...defaultProps} retry={retryMock} />)

    const retryButton = screen.getByRole("button", { name: "Reintentar" })
    await user.click(retryButton)

    expect(retryMock).toHaveBeenCalledTimes(1)
  })

  it("renderiza el enlace Volver a Menú apuntando a la URL configurada", () => {
    render(<OrderError {...defaultProps} homeUrl="/custom-dashboard" />)

    const homeLink = screen.getByRole("link", { name: "Volver a Menú" })
    expect(homeLink).toBeInTheDocument()
    expect(homeLink).toHaveAttribute("href", "/custom-dashboard")
  })
})
