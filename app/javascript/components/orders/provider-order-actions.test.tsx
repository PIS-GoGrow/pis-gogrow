import { act, render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it, vi } from "vitest"

import ProviderOrderActions from "./provider-order-actions"

interface DecisionCallbacks {
  onSuccess: (page: { flash: { alert?: string } }) => void
  onFinish: () => void
}

const patchMock = vi.fn<(...args: unknown[]) => void>()
const onDecided = vi.fn()

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
    onDecided.mockClear()
  })

  it("lets a confirmed order be rejected but not confirmed again", () => {
    render(
      <ProviderOrderActions
        onDecided={onDecided}
        order={{
          id: 1,
          status: "confirmed",
          rejectable: true,
          consumer_name: "Santiago Medina",
        }}
      />,
    )

    expect(screen.getByRole("button", { name: "Rechazar" })).toBeEnabled()
    expect(
      screen.queryByRole("button", { name: "Confirmar" }),
    ).not.toBeInTheDocument()
  })

  it("muestra Rechazar y Confirmar en un pedido por revisar", () => {
    render(
      <ProviderOrderActions
        onDecided={onDecided}
        order={{
          id: 1,
          status: "pending",
          rejectable: true,
          consumer_name: "Santiago Medina",
        }}
      />,
    )

    const reject = screen.getByRole("button", { name: "Rechazar" })
    const confirm = screen.getByRole("button", { name: "Confirmar" })

    expect(screen.getAllByRole("button")).toEqual([reject, confirm])
    expect(reject).toBeEnabled()
    expect(confirm).toBeEnabled()
    expect(reject.parentElement).toHaveClass("grid-cols-2")
  })

  it("deja Rechazar a todo el ancho cuando es la única acción", () => {
    render(
      <ProviderOrderActions
        onDecided={onDecided}
        order={{
          id: 1,
          status: "confirmed",
          rejectable: true,
          consumer_name: "Santiago Medina",
        }}
      />,
    )

    expect(
      screen.getByRole("button", { name: "Rechazar" }).parentElement,
    ).not.toHaveClass("grid-cols-2")
  })

  it("no muestra ningún botón en un confirmado que ya no se puede rechazar", () => {
    const { container } = render(
      <ProviderOrderActions
        onDecided={onDecided}
        order={{
          id: 9,
          status: "confirmed",
          rejectable: false,
          consumer_name: "Santiago Medina",
        }}
      />,
    )

    expect(container).toBeEmptyDOMElement()
  })

  it("renders nothing when the order is cancelled or rejected", () => {
    const { container: cancelledContainer } = render(
      <ProviderOrderActions
        onDecided={onDecided}
        order={{
          id: 2,
          status: "cancelled",
          rejectable: false,
          consumer_name: "Santiago Medina",
        }}
      />,
    )
    expect(cancelledContainer).toBeEmptyDOMElement()

    const { container: rejectedContainer } = render(
      <ProviderOrderActions
        onDecided={onDecided}
        order={{
          id: 3,
          status: "rejected",
          rejectable: false,
          consumer_name: "Santiago Medina",
        }}
      />,
    )
    expect(rejectedContainer).toBeEmptyDOMElement()
  })

  it("pone Confirmar antes de Rechazar en el orden de teclado del detalle móvil", async () => {
    const user = userEvent.setup()
    render(
      <ProviderOrderActions
        onDecided={onDecided}
        order={{
          id: 42,
          status: "pending",
          rejectable: true,
          consumer_name: "Santiago Medina",
        }}
        stackOnMobile
      />,
    )

    const confirm = screen.getByRole("button", { name: "Confirmar" })
    const reject = screen.getByRole("button", { name: "Rechazar" })
    expect(screen.getAllByRole("button")).toEqual([confirm, reject])
    await user.tab()
    expect(confirm).toHaveFocus()
    await user.tab()
    expect(reject).toHaveFocus()
    await user.click(reject)
    expect(screen.getByRole("dialog")).toBeInTheDocument()
    expect(patchMock).not.toHaveBeenCalled()
  })
  it("keeps the buttons enabled on a pending order", () => {
    render(
      <ProviderOrderActions
        onDecided={onDecided}
        order={{
          id: 8,
          status: "pending",
          rejectable: true,
          consumer_name: "Santiago Medina",
        }}
      />,
    )

    expect(screen.getByRole("button", { name: /confirmar/i })).toBeEnabled()
    expect(screen.getByRole("button", { name: /rechazar/i })).toBeEnabled()
  })

  it("renders confirm and reject buttons for pending orders", () => {
    render(
      <ProviderOrderActions
        onDecided={onDecided}
        order={{
          id: 42,
          status: "pending",
          rejectable: true,
          consumer_name: "Santiago Medina",
        }}
      />,
    )

    expect(
      screen.getByRole("button", { name: /confirmar/i }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: /rechazar/i }),
    ).toBeInTheDocument()
  })

  it("sends confirm patch when clicking confirm", async () => {
    const user = userEvent.setup()
    render(
      <ProviderOrderActions
        onDecided={onDecided}
        order={{
          id: 42,
          status: "pending",
          rejectable: true,
          consumer_name: "Santiago Medina",
        }}
      />,
    )

    await user.click(screen.getByRole("button", { name: /confirmar/i }))

    expect(patchMock).toHaveBeenCalledWith(
      expect.objectContaining({ url: "/proveedor/pedidos/42/confirmar" }),
      {},
      expect.objectContaining({ preserveScroll: true }),
    )
  })

  it("opens reject confirmation dialog with confirm button disabled until reason is chosen", async () => {
    const user = userEvent.setup()
    render(
      <ProviderOrderActions
        onDecided={onDecided}
        order={{
          id: 42,
          status: "pending",
          rejectable: true,
          consumer_name: "Santiago Medina",
        }}
      />,
    )

    await user.click(screen.getByRole("button", { name: /rechazar/i }))

    expect(screen.getByText("¿Rechazar pedido?")).toBeInTheDocument()

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
    render(
      <ProviderOrderActions
        onDecided={onDecided}
        order={{
          id: 42,
          status: "pending",
          rejectable: true,
          consumer_name: "Santiago Medina",
        }}
      />,
    )

    await user.click(screen.getByRole("button", { name: /rechazar/i }))

    await user.click(screen.getByLabelText("Sin stock disponible"))

    const confirmRejectBtn = screen.getByRole("button", {
      name: "Rechazar pedido",
    })
    expect(confirmRejectBtn).toBeEnabled()
    await user.click(confirmRejectBtn)

    expect(patchMock).toHaveBeenCalledWith(
      expect.objectContaining({ url: "/proveedor/pedidos/42/rechazar" }),
      {
        reason: "out_of_stock",
        details: null,
      },
      expect.objectContaining({ preserveScroll: true }),
    )
  })

  it("requires text details when 'Otro motivo' is selected before enabling reject button", async () => {
    const user = userEvent.setup()
    render(
      <ProviderOrderActions
        onDecided={onDecided}
        order={{
          id: 42,
          status: "pending",
          rejectable: true,
          consumer_name: "Santiago Medina",
        }}
      />,
    )

    await user.click(screen.getByRole("button", { name: /rechazar/i }))

    await user.click(screen.getByLabelText("Otro motivo"))

    const confirmRejectBtn = screen.getByRole("button", {
      name: "Rechazar pedido",
    })
    // Text input appears and confirm is disabled because textarea is empty
    const textarea = screen.getByPlaceholderText("Describir el motivo")
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
      expect.objectContaining({ url: "/proveedor/pedidos/42/rechazar" }),
      {
        reason: "other",
        details: "Cocina cerrada por reformas",
      },
      expect.objectContaining({ preserveScroll: true }),
    )
  })

  it("conserva el motivo escrito y permite reintentar cuando el servidor devuelve un error", async () => {
    const user = userEvent.setup()
    render(
      <ProviderOrderActions
        onDecided={onDecided}
        order={{
          id: 42,
          status: "pending",
          rejectable: true,
          consumer_name: "Santiago Medina",
        }}
      />,
    )
    await user.click(screen.getByRole("button", { name: "Rechazar" }))
    await user.click(screen.getByLabelText("Otro motivo"))
    await user.type(
      screen.getByPlaceholderText("Describir el motivo"),
      "Cocina cerrada",
    )
    await user.click(screen.getByRole("button", { name: "Rechazar pedido" }))

    const callbacks = patchMock.mock.calls[0][2] as DecisionCallbacks
    act(() => {
      callbacks.onSuccess({ flash: { alert: "No se pudo rechazar" } })
      callbacks.onFinish()
    })

    expect(screen.getByRole("dialog")).toBeInTheDocument()
    expect(screen.getByLabelText("Otro motivo")).toBeChecked()
    expect(screen.getByPlaceholderText("Describir el motivo")).toHaveValue(
      "Cocina cerrada",
    )
    expect(
      screen.getByRole("button", { name: "Rechazar pedido" }),
    ).toBeEnabled()
    await user.click(screen.getByRole("button", { name: "Rechazar pedido" }))
    expect(patchMock).toHaveBeenCalledTimes(2)
  })

  it("cierra y limpia el motivo después de un rechazo exitoso", async () => {
    const user = userEvent.setup()
    render(
      <ProviderOrderActions
        onDecided={onDecided}
        order={{
          id: 42,
          status: "pending",
          rejectable: true,
          consumer_name: "Santiago Medina",
        }}
      />,
    )
    await user.click(screen.getByRole("button", { name: "Rechazar" }))
    await user.click(screen.getByLabelText("Otro motivo"))
    await user.type(
      screen.getByPlaceholderText("Describir el motivo"),
      "Cocina cerrada",
    )
    await user.click(screen.getByRole("button", { name: "Rechazar pedido" }))

    const callbacks = patchMock.mock.calls[0][2] as DecisionCallbacks
    act(() => {
      callbacks.onSuccess({ flash: {} })
      callbacks.onFinish()
    })

    expect(onDecided).toHaveBeenCalledWith({
      id: 42,
      consumer_name: "Santiago Medina",
      status: "rejected",
    })
    expect(screen.queryByText("¿Rechazar pedido?")).not.toBeInTheDocument()

    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
    await user.click(screen.getByRole("button", { name: "Rechazar" }))
    expect(
      screen.getByRole("button", { name: "Rechazar pedido" }),
    ).toBeDisabled()
    expect(screen.getByLabelText("Otro motivo")).not.toBeChecked()
    await user.click(screen.getByLabelText("Otro motivo"))
    expect(screen.getByPlaceholderText("Describir el motivo")).toHaveValue("")
  })
  it("allows cancelling out of the reject dialog without sending a request", async () => {
    const user = userEvent.setup()

    render(
      <ProviderOrderActions
        onDecided={onDecided}
        order={{
          id: 42,
          status: "pending",
          rejectable: true,
          consumer_name: "Santiago Medina",
        }}
      />,
    )

    await user.click(screen.getByRole("button", { name: /rechazar/i }))
    expect(screen.getByText("¿Rechazar pedido?")).toBeInTheDocument()

    const backBtn = screen.getByRole("button", { name: "Volver" })
    await user.click(backBtn)

    expect(patchMock).not.toHaveBeenCalled()
  })
})
