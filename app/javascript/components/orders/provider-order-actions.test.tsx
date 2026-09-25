import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it, vi } from "vitest"

import ProviderOrderActions from "./provider-order-actions"

const patchMock = vi.fn()

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    router: {
      patch: (...args: unknown[]) => {
        patchMock(...args)
      },
    },
  }
})

describe("ProviderOrderActions", () => {
  beforeEach(() => {
    patchMock.mockClear()
  })

  it("renders nothing when the order is not pending", () => {
    const { container } = render(
      <ProviderOrderActions order={{ id: 1, status: "confirmed" }} />,
    )

    expect(container).toBeEmptyDOMElement()
  })

  it("renders nothing when the order is cancelled or rejected", () => {
    const { container: cancelledContainer } = render(
      <ProviderOrderActions order={{ id: 2, status: "cancelled" }} />,
    )
    expect(cancelledContainer).toBeEmptyDOMElement()

    const { container: rejectedContainer } = render(
      <ProviderOrderActions order={{ id: 3, status: "rejected" }} />,
    )
    expect(rejectedContainer).toBeEmptyDOMElement()
  })

  it("renders confirm and reject buttons for pending orders", () => {
    render(<ProviderOrderActions order={{ id: 42, status: "pending" }} />)

    expect(
      screen.getByRole("button", { name: /confirmar/i }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: /rechazar/i }),
    ).toBeInTheDocument()
  })

  it("sends confirm patch when clicking confirm", async () => {
    const user = userEvent.setup()
    render(<ProviderOrderActions order={{ id: 42, status: "pending" }} />)

    await user.click(screen.getByRole("button", { name: /confirmar/i }))

    expect(patchMock).toHaveBeenCalledWith(
      expect.objectContaining({ url: "/provider/orders/42/confirm" }),
      {},
      expect.objectContaining({ preserveScroll: true }),
    )
  })

  it("opens reject confirmation dialog with confirm button disabled until reason is chosen", async () => {
    const user = userEvent.setup()
    render(<ProviderOrderActions order={{ id: 42, status: "pending" }} />)

    await user.click(screen.getByRole("button", { name: /rechazar/i }))

    expect(
      screen.getByText(/¿rechazar el pedido ped-42\?/i),
    ).toBeInTheDocument()

    const confirmRejectBtn = screen.getByRole("button", {
      name: "Rechazar pedido",
    })
    expect(confirmRejectBtn).toBeDisabled()

    // Radio options are visible
    expect(screen.getByLabelText("Sin stock disponible")).toBeInTheDocument()
    expect(screen.getByLabelText("Pedido duplicado")).toBeInTheDocument()
    expect(screen.getByLabelText("Solicitud del cliente")).toBeInTheDocument()
    expect(screen.getByLabelText("Error en el pedido")).toBeInTheDocument()
    expect(screen.getByLabelText("Otro motivo")).toBeInTheDocument()
  })

  it("triggers reject patch with reason when selecting a predefined reason", async () => {
    const user = userEvent.setup()
    render(<ProviderOrderActions order={{ id: 42, status: "pending" }} />)

    await user.click(screen.getByRole("button", { name: /rechazar/i }))

    await user.click(screen.getByLabelText("Sin stock disponible"))

    const confirmRejectBtn = screen.getByRole("button", {
      name: "Rechazar pedido",
    })
    expect(confirmRejectBtn).toBeEnabled()
    await user.click(confirmRejectBtn)

    expect(patchMock).toHaveBeenCalledWith(
      expect.objectContaining({ url: "/provider/orders/42/reject" }),
      {
        reason: "out_of_stock",
        details: null,
      },
      expect.objectContaining({ preserveScroll: true }),
    )
  })

  it("requires text details when 'Otro motivo' is selected before enabling reject button", async () => {
    const user = userEvent.setup()
    render(<ProviderOrderActions order={{ id: 42, status: "pending" }} />)

    await user.click(screen.getByRole("button", { name: /rechazar/i }))

    await user.click(screen.getByLabelText("Otro motivo"))

    const confirmRejectBtn = screen.getByRole("button", {
      name: "Rechazar pedido",
    })
    // Text input appears and confirm is disabled because textarea is empty
    const textarea = screen.getByPlaceholderText("Ingresá el motivo…")
    expect(textarea).toBeInTheDocument()
    expect(confirmRejectBtn).toBeDisabled()

    // Typing spaces only still disables
    await user.type(textarea, "   ")
    expect(confirmRejectBtn).toBeDisabled()

    // Typing valid text enables confirm button
    await user.type(textarea, "Cocina cerrada por reformas")
    expect(confirmRejectBtn).toBeEnabled()

    await user.click(confirmRejectBtn)

    expect(patchMock).toHaveBeenCalledWith(
      expect.objectContaining({ url: "/provider/orders/42/reject" }),
      {
        reason: "other",
        details: "Cocina cerrada por reformas",
      },
      expect.objectContaining({ preserveScroll: true }),
    )
  })

  it("allows cancelling out of the reject dialog without sending a request", async () => {
    const user = userEvent.setup()

    render(<ProviderOrderActions order={{ id: 42, status: "pending" }} />)

    await user.click(screen.getByRole("button", { name: /rechazar/i }))
    expect(
      screen.getByText(/¿rechazar el pedido ped-42\?/i),
    ).toBeInTheDocument()

    const backBtn = screen.getByRole("button", { name: "Volver" })
    await user.click(backBtn)

    expect(patchMock).not.toHaveBeenCalled()
  })
})
