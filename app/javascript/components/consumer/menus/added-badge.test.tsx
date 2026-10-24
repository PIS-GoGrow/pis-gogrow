import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import AddedBadge from "./added-badge"

describe("AddedBadge", () => {
  it("renders the badge with text Agregado and the indicator dot", () => {
    const { container } = render(<AddedBadge />)

    expect(screen.getByText("Agregado")).toBeInTheDocument()
    const dot = container.querySelector("span.size-1\\.5.rounded-full.bg-blue-500")
    expect(dot).toBeInTheDocument()
  })

  it("applies the expected badge styling classes", () => {
    render(<AddedBadge />)

    const badge = screen.getByText("Agregado").closest("span")
    expect(badge).toHaveClass("bg-blue-50")
    expect(badge).toHaveClass("text-blue-700")
  })
})
