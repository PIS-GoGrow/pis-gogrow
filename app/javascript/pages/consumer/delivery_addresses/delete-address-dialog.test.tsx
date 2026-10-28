import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it, vi } from "vitest"

import type { ConsumerDeliveryAddress } from "@/types"

import DeleteAddressDialog from "./delete-address-dialog"

const { deleteMock } = vi.hoisted(() => ({
  deleteMock: vi.fn(),
}))

vi.mock("@inertiajs/react", () => ({
  router: {
    delete: deleteMock,
  },
}))

const address: ConsumerDeliveryAddress = {
  id: 12,
  name: "Flora Café",
  street: "Canelones 892",
  apartment: null,
  address: "Canelones 892",
}

interface DeleteOptions {
  onSuccess?: () => void
  onFinish?: () => void
}

describe("DeleteAddressDialog", () => {
  beforeEach(() => {
    deleteMock.mockReset()
  })

  it("shows the address deletion confirmation", () => {
    render(
      <DeleteAddressDialog address={address} open onOpenChange={vi.fn()} />,
    )

    expect(
      screen.getByRole("heading", { name: "¿Eliminar Flora Café?" }),
    ).toBeInTheDocument()

    expect(
      screen.getByText(
        "Esta dirección no podrá recuperarse. Podés agregar una nueva cuando quieras.",
      ),
    ).toBeInTheDocument()

    expect(screen.getByRole("button", { name: "Volver" })).toBeInTheDocument()

    expect(
      screen.getByRole("button", { name: "Eliminar dirección" }),
    ).toBeInTheDocument()
  })

  it("closes without deleting when the employee goes back", async () => {
    const user = userEvent.setup()
    const onOpenChange = vi.fn()

    render(
      <DeleteAddressDialog
        address={address}
        open
        onOpenChange={onOpenChange}
      />,
    )

    await user.click(screen.getByRole("button", { name: "Volver" }))

    expect(deleteMock).not.toHaveBeenCalled()
    expect(onOpenChange).toHaveBeenCalledWith(false)
  })

  it("deletes the selected address", async () => {
    const user = userEvent.setup()

    render(
      <DeleteAddressDialog address={address} open onOpenChange={vi.fn()} />,
    )

    await user.click(screen.getByRole("button", { name: "Eliminar dirección" }))

    expect(deleteMock).toHaveBeenCalledTimes(1)
    expect(deleteMock).toHaveBeenCalledWith(
      "/direcciones-de-entrega/12",
      expect.objectContaining({
        preserveScroll: true,
        preserveState: true,
      }),
    )
  })

  it("shows the success state after deletion", async () => {
    const user = userEvent.setup()

    deleteMock.mockImplementation((_url: string, options?: DeleteOptions) => {
      options?.onSuccess?.()
      options?.onFinish?.()
    })

    render(
      <DeleteAddressDialog address={address} open onOpenChange={vi.fn()} />,
    )

    await user.click(screen.getByRole("button", { name: "Eliminar dirección" }))

    expect(
      screen.getByRole("heading", { name: "Dirección eliminada" }),
    ).toBeInTheDocument()

    expect(screen.getByRole("button", { name: "Listo" })).toBeInTheDocument()
  })
})
