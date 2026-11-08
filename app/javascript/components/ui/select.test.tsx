import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeAll, describe, expect, it, vi } from "vitest"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "./select"

beforeAll(() => {
  window.HTMLElement.prototype.hasPointerCapture = vi.fn()
  window.HTMLElement.prototype.setPointerCapture = vi.fn()
  window.HTMLElement.prototype.releasePointerCapture = vi.fn()
  window.HTMLElement.prototype.scrollIntoView = vi.fn()
})

describe("Select component", () => {
  it("renders trigger and allows selecting an item", async () => {
    const handleValueChange = vi.fn()
    render(
      <div id="modal-wrapper">
        <h2>Modal Title</h2>
        <Select onValueChange={handleValueChange}>
          <SelectTrigger aria-label="Frutas">
            <SelectValue placeholder="Elegí una fruta" />
          </SelectTrigger>
          <SelectContent inFlow>
            <SelectItem value="manzana">Manzana</SelectItem>
            <SelectItem value="banana">Banana</SelectItem>
          </SelectContent>
        </Select>
        <button type="button">Guardar cambios</button>
      </div>,
    )

    const trigger = screen.getByRole("combobox", { name: "Frutas" })
    expect(trigger).toBeInTheDocument()

    await userEvent.click(trigger)

    const option = screen.getByRole("option", { name: "Manzana" })
    expect(option).toBeInTheDocument()

    await userEvent.click(option)
    expect(handleValueChange).toHaveBeenCalledWith("manzana")
  })
})
