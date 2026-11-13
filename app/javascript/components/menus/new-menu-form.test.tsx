import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it } from "vitest"

import type { ProviderMenusNew } from "@/types"

import MenuForm from "./new-menu-form"

describe("MenuForm", () => {
  const createProps: ProviderMenusNew = {
    today: "2030-01-09",
    maximum_publish_date: "2030-01-18",
    default_date: null,
    saved_menus: [],
    published: [],
  }

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

  it("shows error when repeating every week without selecting weekdays", async () => {
    const user = userEvent.setup()
    render(<MenuForm create={createProps} />)

    await user.type(screen.getByLabelText(/Nombre del plato/), "Milanesa")
    await user.type(screen.getByLabelText(/Descripción/), "Con papas")
    await user.type(screen.getByLabelText(/Precio/), "350")

    // El alta arranca con el día de hoy elegido: hay que soltarlo para
    // llegar al caso sin días.
    await user.click(screen.getByLabelText("Miércoles"))
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

    await user.click(screen.getByLabelText("Miércoles"))
    await user.click(screen.getByLabelText("Repetir en un rango personalizado"))

    const [, submit] = screen.getAllByRole("button", { name: "Agregar" })
    await user.click(submit)

    expect(
      screen.getByText("Elegí al menos un día de lunes a viernes."),
    ).toBeInTheDocument()
  })

  it("starts the agenda on today when there is no day of origin", () => {
    // 2030-01-09 es miércoles.
    render(<MenuForm create={createProps} />)

    expect(screen.getByLabelText("Miércoles")).toHaveAttribute(
      "data-state",
      "on",
    )
    expect(screen.getByLabelText("Lunes")).toHaveAttribute("data-state", "off")
    expect(screen.getByText("Día específico")).toBeInTheDocument()
  })

  it("keeps the day of origin when it comes from a specific day", () => {
    // 2030-01-11 es viernes.
    render(<MenuForm create={{ ...createProps, default_date: "2030-01-11" }} />)

    expect(screen.getByLabelText("Viernes")).toHaveAttribute("data-state", "on")
    expect(screen.getByLabelText("Miércoles")).toHaveAttribute(
      "data-state",
      "off",
    )
  })

  it("starts with no day when today cannot be published", () => {
    // 2030-01-12 es sábado: no es día hábil.
    render(
      <MenuForm
        create={{
          ...createProps,
          today: "2030-01-12",
          maximum_publish_date: "2030-01-25",
        }}
      />,
    )

    for (const day of ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes"]) {
      expect(screen.getByLabelText(day)).toHaveAttribute("data-state", "off")
    }
  })

  it("renders form with noValidate to bypass native browser tooltips", () => {
    const { container } = render(<MenuForm />)
    const form = container.querySelector("form")

    expect(form).toHaveAttribute("noValidate")
  })
})
