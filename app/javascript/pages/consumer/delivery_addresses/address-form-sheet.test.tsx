import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it, vi } from "vitest"

import type { ConsumerDeliveryAddress } from "@/types"

import AddressFormSheet from "./address-form-sheet"

const formMock = vi.hoisted(() => ({
  post: vi.fn(),
  patch: vi.fn(),
  reset: vi.fn(),
  clearErrors: vi.fn(),
  setData: vi.fn(),
  transform: vi.fn(),
  processing: false,
  errors: {},
}))

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    useForm: (initialValues: Record<string, unknown>) => ({
      data: initialValues,
      setData: formMock.setData,
      post: formMock.post,
      patch: formMock.patch,
      processing: formMock.processing,
      errors: formMock.errors,
      clearErrors: formMock.clearErrors,
      reset: formMock.reset,
      transform: formMock.transform,
    }),
  }
})

const existingAddress: ConsumerDeliveryAddress = {
  id: 42,
  name: "Casa",
  street: "Ellauri 1234",
  apartment: "Apto 301",
  address: "Ellauri 1234, Apto 301",
}

describe("AddressFormSheet", () => {
  beforeEach(() => {
    vi.clearAllMocks()
    formMock.errors = {}
  })

  it("renders create form when no address is provided", async () => {
    const user = userEvent.setup()
    render(
      <AddressFormSheet>
        <button type="button">Abrir</button>
      </AddressFormSheet>,
    )

    await user.click(screen.getByRole("button", { name: "Abrir" }))

    expect(
      screen.getByRole("heading", { name: "Agregar una dirección" }),
    ).toBeInTheDocument()
    expect(screen.getByLabelText("Nombre")).toHaveValue("")
    expect(screen.getByLabelText("Dirección")).toHaveValue("")
    expect(screen.getByLabelText("Piso/Apartamento (opcional)")).toHaveValue("")
    expect(
      screen.queryByRole("button", { name: "Eliminar" }),
    ).not.toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Agregar" })).toBeInTheDocument()
  })

  it("submits the create form via POST", async () => {
    const user = userEvent.setup()
    render(
      <AddressFormSheet>
        <button type="button">Abrir</button>
      </AddressFormSheet>,
    )

    await user.click(screen.getByRole("button", { name: "Abrir" }))
    await user.click(screen.getByRole("button", { name: "Agregar" }))

    expect(formMock.transform).toHaveBeenCalledTimes(1)
    expect(formMock.post).toHaveBeenCalledWith(
      "/direcciones-de-entrega",
      expect.objectContaining({ preserveScroll: true }),
    )
  })

  it("renders edit form when an existing address is provided", async () => {
    const user = userEvent.setup()
    render(
      <AddressFormSheet address={existingAddress}>
        <button type="button">Editar</button>
      </AddressFormSheet>,
    )

    await user.click(screen.getByRole("button", { name: "Editar" }))

    expect(
      screen.getByRole("heading", { name: "Editar dirección" }),
    ).toBeInTheDocument()
    expect(screen.getByLabelText("Nombre")).toHaveValue("Casa")
    expect(screen.getByLabelText("Dirección")).toHaveValue("Ellauri 1234")
    expect(screen.getByLabelText("Piso/Apartamento (opcional)")).toHaveValue(
      "Apto 301",
    )
    expect(
      screen.getByRole("button", { name: "Guardar cambios" }),
    ).toBeInTheDocument()
  })

  it("submits the edit form via PATCH", async () => {
    const user = userEvent.setup()
    render(
      <AddressFormSheet address={existingAddress}>
        <button type="button">Editar</button>
      </AddressFormSheet>,
    )

    await user.click(screen.getByRole("button", { name: "Editar" }))
    await user.click(screen.getByRole("button", { name: "Guardar cambios" }))

    expect(formMock.transform).toHaveBeenCalledTimes(1)
    expect(formMock.patch).toHaveBeenCalledWith(
      "/direcciones-de-entrega/42",
      expect.objectContaining({ preserveScroll: true }),
    )
  })

  it("triggers onDelete callback when clicking the delete button in edit mode", async () => {
    const user = userEvent.setup()
    const onDelete = vi.fn()

    render(
      <AddressFormSheet address={existingAddress} onDelete={onDelete}>
        <button type="button">Editar</button>
      </AddressFormSheet>,
    )

    await user.click(screen.getByRole("button", { name: "Editar" }))
    const deleteButton = screen.getByRole("button", { name: "Eliminar" })
    await user.click(deleteButton)

    expect(onDelete).toHaveBeenCalledWith(existingAddress)
  })

  it("displays server validation errors under corresponding fields", async () => {
    const user = userEvent.setup()
    formMock.errors = {
      name: ["El nombre es obligatorio"],
      street: ["Incluí el número de puerta"],
    }

    render(
      <AddressFormSheet>
        <button type="button">Abrir</button>
      </AddressFormSheet>,
    )

    await user.click(screen.getByRole("button", { name: "Abrir" }))

    expect(screen.getByText("El nombre es obligatorio")).toBeInTheDocument()
    expect(screen.getByText("Incluí el número de puerta")).toBeInTheDocument()
    expect(screen.getByLabelText("Nombre")).toHaveAttribute(
      "aria-invalid",
      "true",
    )
    expect(screen.getByLabelText("Dirección")).toHaveAttribute(
      "aria-invalid",
      "true",
    )
  })
})
