import { fireEvent, render, screen } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import FeatureCarousel from "./feature-carousel"

describe("FeatureCarousel", () => {
  const scrollToMock = vi.fn()

  beforeEach(() => {
    scrollToMock.mockClear()
    Element.prototype.scrollTo = scrollToMock
  })

  it("renders carousel section with accessible role and label", () => {
    render(<FeatureCarousel />)

    const carousel = screen.getByRole("region", {
      name: "Qué podés hacer en Viandas GoGrow",
    })
    expect(carousel).toHaveAttribute("aria-roledescription", "carousel")
  })

  it("renders all three feature slides with their headings", () => {
    const { container } = render(<FeatureCarousel />)

    const slides = container.querySelectorAll('[aria-roledescription="slide"]')
    expect(slides).toHaveLength(3)

    expect(screen.getByText("Tu menú, siempre actualizado")).toBeInTheDocument()
    expect(
      screen.getByText("Todos tus pedidos bajo control"),
    ).toBeInTheDocument()
    expect(screen.getByText("Cobros claros y ordenados")).toBeInTheDocument()
  })

  it("renders pagination buttons and scrolls on click", () => {
    render(<FeatureCarousel />)

    const firstButton = screen.getByRole("button", {
      name: "Ver la tarjeta 1",
    })
    const secondButton = screen.getByRole("button", {
      name: "Ver la tarjeta 2",
    })
    const thirdButton = screen.getByRole("button", {
      name: "Ver la tarjeta 3",
    })

    expect(firstButton).toHaveAttribute("aria-current", "true")
    expect(secondButton).toHaveAttribute("aria-current", "false")
    expect(thirdButton).toHaveAttribute("aria-current", "false")

    fireEvent.click(secondButton)

    expect(scrollToMock).toHaveBeenCalledWith(
      expect.objectContaining({ behavior: "smooth" }),
    )
  })
})
