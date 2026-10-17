import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it } from "vitest"

import AppearanceTabs from "./appearance-tabs"

describe("AppearanceTabs", () => {
  beforeEach(() => {
    localStorage.clear()
    document.documentElement.classList.remove("dark")
  })

  it("offers light, dark and system modes and applies the selection", async () => {
    const user = userEvent.setup()
    render(<AppearanceTabs />)

    expect(screen.getByRole("button", { name: "Claro" })).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Oscuro" })).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Sistema" })).toBeInTheDocument()

    await user.click(screen.getByRole("button", { name: "Oscuro" }))

    expect(document.documentElement).toHaveClass("dark")
    expect(localStorage.getItem("appearance")).toBe("dark")

    await user.click(screen.getByRole("button", { name: "Sistema" }))

    expect(document.documentElement).not.toHaveClass("dark")
    expect(localStorage.getItem("appearance")).toBeNull()
  })
})
