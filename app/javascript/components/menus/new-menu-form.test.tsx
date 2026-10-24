import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it } from "vitest"

import MenuForm from "./new-menu-form"

describe("MenuForm", () => {
  it("shows every missing field at once in Spanish", async () => {
    const user = userEvent.setup()
    render(<MenuForm />)

    const [, submit] = screen.getAllByRole("button", { name: "Agregar" })
    await user.click(submit)

    expect(screen.getAllByRole("alert")).toHaveLength(3)
    expect(screen.getAllByText("No puede estar vacío.")).toHaveLength(3)
    expect(screen.getByLabelText(/Nombre del plato/)).toHaveAttribute(
      "aria-invalid",
      "true",
    )
  })

  it("drops empty options from the group summary", async () => {
    const user = userEvent.setup()
    render(<MenuForm />)

    const [addGroup] = screen.getAllByRole("button", { name: "Agregar" })
    await user.click(addGroup)
    const dialog = await screen.findByRole("dialog")
    await user.type(within(dialog).getByLabelText("Nombre del grupo"), "Salsa")
    await user.type(
      within(dialog).getByLabelText("Opciones"),
      "Bolognesa, Caruso, , Pesto,",
    )
    await user.click(within(dialog).getByRole("button", { name: "Agregar" }))

    expect(
      await screen.findByText("Bolognesa, Caruso, Pesto"),
    ).toBeInTheDocument()
  })

  it("rejects a price that is not above zero before submitting", async () => {
    const user = userEvent.setup()
    render(<MenuForm />)

    await user.type(screen.getByLabelText(/Nombre del plato/), "Wok")
    await user.type(screen.getByLabelText(/Descripción/), "Salteado")
    await user.type(screen.getByLabelText(/Precio/), "0")
    const [, submit] = screen.getAllByRole("button", { name: "Agregar" })
    await user.click(submit)

    expect(screen.getByText("Tiene que ser mayor que 0.")).toBeInTheDocument()
  })

  it("rejects a negative price before submitting", async () => {
    const user = userEvent.setup()
    render(<MenuForm />)

    await user.type(screen.getByLabelText(/Nombre del plato/), "Wok")
    await user.type(screen.getByLabelText(/Descripción/), "Salteado")
    await user.type(screen.getByLabelText(/Precio/), "-10")
    const [, submit] = screen.getAllByRole("button", { name: "Agregar" })
    await user.click(submit)

    expect(screen.getByText("Tiene que ser mayor que 0.")).toBeInTheDocument()
  })

  it("renders form with noValidate to bypass native browser tooltips", () => {
    const { container } = render(<MenuForm />)
    const form = container.querySelector("form")

    expect(form).toHaveAttribute("noValidate")
  })
})
