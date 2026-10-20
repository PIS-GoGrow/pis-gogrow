import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it } from "vitest"

import MenuForm from "./new-menu-form"

describe("MenuForm", () => {
  it("shows every missing field at once in Spanish", async () => {
    const user = userEvent.setup()
    render(<MenuForm />)

    const [, submit] = screen.getAllByRole("button", { name: "Agregar" })
    await user.click(submit)

    expect(screen.getAllByText("No puede estar vacío.")).toHaveLength(3)
  })
})
