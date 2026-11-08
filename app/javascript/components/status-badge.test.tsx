import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import StatusBadge from "./status-badge"

describe("StatusBadge", () => {
  it("renders partial as a payment status distinct from rejected", () => {
    render(<StatusBadge status="partial" kind="payment" />)

    const badge = screen.getByText("Pago parcial").closest("span")
    expect(badge).toHaveAttribute("data-status", "partial")
    expect(screen.queryByText("Rechazado")).not.toBeInTheDocument()
  })
})
