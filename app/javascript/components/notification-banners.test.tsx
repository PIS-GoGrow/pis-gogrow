import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it, vi } from "vitest"

import NotificationBanners from "./notification-banners"

const mocks = vi.hoisted(() => ({
  patch: vi.fn(),
  notifications: [] as {
    id: number
    title: string
    description: string
    requires_action: boolean
  }[],
}))

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")

  return {
    ...actual,
    usePage: () => ({
      props: {
        notifications: mocks.notifications,
      },
    }),
    router: {
      patch: (...args: unknown[]) => {
        mocks.patch(...args)
      },
    },
  }
})

describe("NotificationBanners", () => {
  beforeEach(() => {
    mocks.patch.mockClear()
    mocks.notifications.splice(0)
  })

  it("renders nothing when there are no active notifications", () => {
    const { container } = render(<NotificationBanners />)

    expect(container).toBeEmptyDOMElement()
  })

  it("renders a dismissable notification with a close button", () => {
    mocks.notifications.push({
      id: 1,
      title: "Tu pedido fue cancelado",
      description: "Tu pedido no podrá ser entregado.",
      requires_action: false,
    })

    render(<NotificationBanners />)

    expect(screen.getByText("Tu pedido fue cancelado")).toBeInTheDocument()
    expect(
      screen.getByText("Tu pedido no podrá ser entregado."),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Cerrar notificación" }),
    ).toBeInTheDocument()
  })

  it("renders a notification that requires action without a close button", () => {
    mocks.notifications.push({
      id: 2,
      title: "Tenés un pago pendiente",
      description: "Realizá el pago para continuar.",
      requires_action: true,
    })

    render(<NotificationBanners />)

    expect(screen.getByText("Tenés un pago pendiente")).toBeInTheDocument()
    expect(
      screen.queryByRole("button", { name: "Cerrar notificación" }),
    ).not.toBeInTheDocument()
  })

  it("sends the close request when the dismiss button is clicked", async () => {
    const user = userEvent.setup()

    mocks.notifications.push({
      id: 42,
      title: "Tu pedido fue cancelado",
      description: "Tu pedido no podrá ser entregado.",
      requires_action: false,
    })

    render(<NotificationBanners />)

    await user.click(
      screen.getByRole("button", { name: "Cerrar notificación" }),
    )

    expect(mocks.patch).toHaveBeenCalledWith(
      expect.objectContaining({
        url: "/notifications/42/close",
        method: "patch",
      }),
      {},
      expect.objectContaining({
        preserveScroll: true,
      }),
    )
  })
})
