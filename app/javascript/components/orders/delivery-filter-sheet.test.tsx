import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import DeliveryFilterSheet from "./delivery-filter-sheet"

const trigger = { name: "Filtrar por tipo de entrega" }

describe("DeliveryFilterSheet", () => {
  it("muestra el botón de filtro", () => {
    render(<DeliveryFilterSheet value="all" onApply={vi.fn()} />)

    expect(screen.getByRole("button", trigger)).toBeInTheDocument()
  })

  it("abre con el título y las tres opciones, marcando la actual", async () => {
    const user = userEvent.setup()
    render(<DeliveryFilterSheet value="office" onApply={vi.fn()} />)

    await user.click(screen.getByRole("button", trigger))

    expect(screen.getByText("Filtrar por Tipo de entrega")).toBeInTheDocument()
    expect(screen.getByLabelText("Todas")).not.toBeChecked()
    expect(screen.getByLabelText("Oficina GoGrow")).toBeChecked()
    expect(screen.getByLabelText("Domicilios")).not.toBeChecked()
  })

  it("aplica la opción elegida", async () => {
    const user = userEvent.setup()
    const onApply = vi.fn()
    render(<DeliveryFilterSheet value="all" onApply={onApply} />)

    await user.click(screen.getByRole("button", trigger))
    await user.click(screen.getByLabelText("Domicilios"))

    expect(screen.getByLabelText("Domicilios")).toBeChecked()
    expect(screen.getByLabelText("Todas")).not.toBeChecked()

    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expect(onApply).toHaveBeenCalledWith("home")
  })

  it("descarta el borrador al cancelar", async () => {
    const user = userEvent.setup()
    const onApply = vi.fn()
    render(<DeliveryFilterSheet value="all" onApply={onApply} />)

    await user.click(screen.getByRole("button", trigger))
    await user.click(screen.getByLabelText("Oficina GoGrow"))
    await user.click(screen.getByRole("button", { name: "Cancelar" }))

    expect(onApply).not.toHaveBeenCalled()

    await user.click(screen.getByRole("button", trigger))

    expect(screen.getByLabelText("Todas")).toBeChecked()
  })
})
