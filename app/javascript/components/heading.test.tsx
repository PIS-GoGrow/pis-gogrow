import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import Heading from "./heading"

describe("Heading", () => {
  it("renders title, description and actions", () => {
    render(
      <Heading
        title="Inicio"
        description="Lunes 10 de noviembre"
        actions={<button type="button">Campana</button>}
      />,
    )

    expect(screen.getByRole("heading", { name: "Inicio" })).toBeInTheDocument()
    expect(screen.getByText("Lunes 10 de noviembre")).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Campana" })).toBeInTheDocument()
  })

  it("applies actionsCentered styles when actionsCentered is true", () => {
    const { container } = render(
      <Heading
        title="Inicio"
        actionsCentered
        actions={<button type="button">Campana</button>}
      />,
    )

    const flexContainer = container.querySelector(".flex.gap-4")
    expect(flexContainer).toHaveClass("items-center")
    expect(flexContainer).not.toHaveClass("items-end")

    const headingElement = screen.getByRole("heading", { name: "Inicio" })
    const titleWrapper = headingElement.closest(".space-y-0\\.5")
    expect(titleWrapper).toHaveClass("min-w-0")
  })

  it("defaults to items-end without min-w-0 when actionsCentered is false", () => {
    const { container } = render(
      <Heading
        title="Inicio"
        actions={<button type="button">Campana</button>}
      />,
    )

    const flexContainer = container.querySelector(".flex.gap-4")
    expect(flexContainer).toHaveClass("items-end")
    expect(flexContainer).not.toHaveClass("items-center")

    const headingElement = screen.getByRole("heading", { name: "Inicio" })
    const titleWrapper = headingElement.closest(".space-y-0\\.5")
    expect(titleWrapper).not.toHaveClass("min-w-0")
  })
})
