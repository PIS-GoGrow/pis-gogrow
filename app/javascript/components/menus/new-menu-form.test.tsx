import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it } from "vitest"

import type { ProviderMenusNew } from "@/types"
import MenuForm from "./new-menu-form"

describe("MenuForm", () => {
  const createProps: ProviderMenusNew = {
    today: "2030-01-09",
    maximum_publish_date: "2030-01-18",
    default_date: null,
  }

  it("shows every missing field at once in Spanish", async () => {
    const user = userEvent.setup()
    render(<MenuForm />)

    const [, submit] = screen.getAllByRole("button", { name: "Agregar" })
    await user.click(submit)

    expect(screen.getAllByText("No puede estar vacío.")).toHaveLength(3)
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

  it("shows error when repeating every week without selecting weekdays", async () => {
    const user = userEvent.setup()
    render(<MenuForm create={createProps} />)

    await user.type(screen.getByLabelText(/Nombre del plato/), "Milanesa")
    await user.type(screen.getByLabelText(/Descripción/), "Con papas")
    await user.type(screen.getByLabelText(/Precio/), "350")

    await user.click(screen.getByLabelText("Repetir todas las semanas"))

    const [, submit] = screen.getAllByRole("button", { name: "Agregar" })
    await user.click(submit)

    expect(
      screen.getByText("Elegí al menos un día de lunes a viernes."),
    ).toBeInTheDocument()
  })

  it("shows error when repeating in a custom range without selecting weekdays", async () => {
    const user = userEvent.setup()
    render(<MenuForm create={createProps} />)

    await user.type(screen.getByLabelText(/Nombre del plato/), "Milanesa")
    await user.type(screen.getByLabelText(/Descripción/), "Con papas")
    await user.type(screen.getByLabelText(/Precio/), "350")

    await user.click(screen.getByLabelText("Repetir en un rango personalizado"))

    const [, submit] = screen.getAllByRole("button", { name: "Agregar" })
    await user.click(submit)

    expect(
      screen.getByText("Elegí al menos un día de lunes a viernes."),
    ).toBeInTheDocument()
  })

  it("renders form with noValidate to bypass native browser tooltips", () => {
    const { container } = render(<MenuForm />)
    const form = container.querySelector("form")

    expect(form).toHaveAttribute("noValidate")
  })
})
