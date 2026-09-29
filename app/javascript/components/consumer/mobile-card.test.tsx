import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import { BottomAction, MobileCard } from "./mobile-card"

describe("MobileCard and BottomAction components", () => {
  it("renders MobileCard with children and custom className", () => {
    render(
      <MobileCard className="custom-class" data-testid="mobile-card">
        <span>Contenido del Card</span>
      </MobileCard>,
    )

    const card = screen.getByTestId("mobile-card")
    expect(card).toBeInTheDocument()
    expect(card).toHaveClass("custom-class")
    expect(screen.getByText("Contenido del Card")).toBeInTheDocument()
  })

  it("renders BottomAction with children", () => {
    render(
      <BottomAction data-testid="bottom-action">
        <button type="button">Acción</button>
      </BottomAction>,
    )

    const action = screen.getByTestId("bottom-action")
    expect(action).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Acción" })).toBeInTheDocument()
  })
})
