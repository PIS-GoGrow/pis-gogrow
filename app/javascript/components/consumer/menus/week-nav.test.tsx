import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import WeekNav from "./week-nav"

// IBP-003, criterios 1 y 2: el selector es por donde el empleado "selecciona
// una fecha". Lo que se prueba acá es el cálculo de la semana laboral y qué
// fecha emite al elegir un día — nada de eso pasa por el server.
const dayNumbers = () =>
  within(screen.getByRole("radiogroup"))
    .getAllByRole("radio")
    .map((day) => day.textContent?.replace(/\D/g, ""))

describe("WeekNav", () => {
  it("shows the monday to friday week of the given date", () => {
    // Miércoles 2026-09-16: la semana va del lunes 14 al viernes 18.
    render(<WeekNav date="2026-09-16" onChange={vi.fn()} />)

    expect(dayNumbers()).toEqual(["14", "15", "16", "17", "18"])
  })

  it("shows the same week from its monday and from its friday", () => {
    const { unmount } = render(<WeekNav date="2026-09-14" onChange={vi.fn()} />)
    expect(dayNumbers()).toEqual(["14", "15", "16", "17", "18"])
    unmount()

    render(<WeekNav date="2026-09-18" onChange={vi.fn()} />)
    expect(dayNumbers()).toEqual(["14", "15", "16", "17", "18"])
  })

  it("keeps the week that crosses into the next month whole", () => {
    // Lunes 2026-09-28: el viernes de esa semana ya es 2 de octubre.
    render(<WeekNav date="2026-09-28" onChange={vi.fn()} />)

    expect(dayNumbers()).toEqual(["28", "29", "30", "1", "2"])
  })

  it("reports the date of the day picked", async () => {
    const user = userEvent.setup()
    const onChange = vi.fn()
    render(<WeekNav date="2026-09-16" onChange={onChange} />)

    const thursday = within(screen.getByRole("radiogroup")).getAllByRole(
      "radio",
    )[3]
    await user.click(thursday)

    expect(onChange).toHaveBeenCalledWith("2026-09-17")
  })

  it("moves a whole week back and forward from the arrows", async () => {
    const user = userEvent.setup()
    const onChange = vi.fn()
    render(<WeekNav date="2026-09-16" onChange={onChange} />)

    await user.click(screen.getByRole("button", { name: "Semana anterior" }))
    expect(onChange).toHaveBeenLastCalledWith("2026-09-07")

    await user.click(screen.getByRole("button", { name: "Semana siguiente" }))
    expect(onChange).toHaveBeenLastCalledWith("2026-09-21")
  })

  it("hides the arrows when asked to", () => {
    render(<WeekNav date="2026-09-16" onChange={vi.fn()} showArrows={false} />)

    expect(
      screen.queryByRole("button", { name: "Semana anterior" }),
    ).not.toBeInTheDocument()
  })

  // TODO(integración): falta corregir el cálculo del fin de semana antes de
  // poder testear que un sábado o un domingo queden representados en el
  // selector. Hoy getMondayOf() devuelve el lunes de la semana que ya terminó,
  // así que ninguno de los cinco días coincide con la fecha consultada y el
  // selector queda sin día marcado mientras el encabezado anuncia esa fecha.
  // Está registrado como defecto (DEFECT-weeknav-sin-dia-seleccionado-fin-de-
  // semana): no se fija acá el comportamiento actual como si fuera correcto.
})
