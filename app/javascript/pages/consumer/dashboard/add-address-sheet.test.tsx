import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it, vi } from "vitest"

import { AddAddressSheet } from "./add-address-sheet"

// El servidor es el que valida (POST /delivery_addresses); acá se simula su
// respuesta para ver qué hace el formulario con ella.
const form = vi.hoisted(() => ({
  data: { name: "", street: "", apartment: "", save_for_later: false },
  errors: {},
  post: vi.fn(),
  reset: vi.fn(),
  clearErrors: vi.fn(),
}))

vi.mock("@inertiajs/react", () => ({
  useForm: () => ({
    ...form,
    setData: vi.fn(),
    processing: false,
    transform: vi.fn(),
  }),
}))

// IBP-014 — criterio 2: el sistema solicita y valida los campos obligatorios
// de dirección; criterio 3: el empleado puede corregirla antes de confirmar.
describe("AddAddressSheet", () => {
  beforeEach(() => {
    vi.clearAllMocks()
    form.data = { name: "", street: "", apartment: "", save_for_later: false }
    form.errors = {}
  })

  async function openSheet(onAdd = vi.fn()) {
    const user = userEvent.setup()
    render(<AddAddressSheet onAdd={onAdd} />)
    await user.click(screen.getByRole("button", { name: "Agregar" }))
    const sheet = screen.getByRole("dialog", { name: "Agregar una dirección" })
    return { user, sheet, onAdd }
  }

  it("shows the server's error under each invalid field", async () => {
    form.errors = {
      name: ["Ingresá un nombre"],
      street: ["Incluí el número de puerta"],
      apartment: ["Es demasiado largo"],
    }
    const { sheet } = await openSheet()

    expect(within(sheet).getByLabelText("Nombre")).toHaveAttribute(
      "aria-invalid",
      "true",
    )
    expect(within(sheet).getByText("Ingresá un nombre")).toBeInTheDocument()
    expect(
      within(sheet).getByText("Incluí el número de puerta"),
    ).toBeInTheDocument()
    expect(within(sheet).getByText("Es demasiado largo")).toBeInTheDocument()
  })

  it("does not add the address while the server rejects it", async () => {
    form.data = { ...form.data, street: "Ellauri" }
    const { user, sheet, onAdd } = await openSheet()

    await user.click(within(sheet).getByRole("button", { name: "Agregar" }))

    expect(form.post).toHaveBeenCalledOnce()
    expect(onAdd).not.toHaveBeenCalled()
    expect(sheet).toBeInTheDocument()
  })

  it("adds the address the server accepted, squished, and closes", async () => {
    form.data = {
      name: "  Flora   Café ",
      street: " Canelones  892 ",
      apartment: " Apto 3 ",
      save_for_later: true,
    }
    form.post.mockImplementation(
      (_url: string, options: { onSuccess: () => void }) => options.onSuccess(),
    )
    const { user, sheet, onAdd } = await openSheet()

    await user.click(within(sheet).getByRole("button", { name: "Agregar" }))

    expect(onAdd).toHaveBeenCalledWith(
      expect.objectContaining({
        label: "Flora Café",
        address: "Canelones 892, Apto 3",
      }),
      true,
    )
    expect(
      screen.queryByRole("dialog", { name: "Agregar una dirección" }),
    ).not.toBeInTheDocument()
    expect(form.reset).toHaveBeenCalled()
  })

  it("discards what was typed and its errors on cancel", async () => {
    form.errors = { street: ["Incluí el número de puerta"] }
    const { user, sheet, onAdd } = await openSheet()

    await user.click(within(sheet).getByRole("button", { name: "Cancelar" }))

    expect(form.reset).toHaveBeenCalled()
    expect(form.clearErrors).toHaveBeenCalled()
    expect(onAdd).not.toHaveBeenCalled()
    expect(
      screen.queryByRole("dialog", { name: "Agregar una dirección" }),
    ).not.toBeInTheDocument()
  })
})
