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

  it("renders a payment approved notification for consumer and can be dismissed", () => {
    mocks.notifications.push({
      id: 88,
      title: "Pago aprobado",
      description: "Rotisería Central aprobó tu comprobante de pago correspondiente a octubre 2026.",
      requires_action: false,
    })

    render(<NotificationBanners />)

    expect(screen.getByText("Pago aprobado")).toBeInTheDocument()
    expect(
      screen.getByText(
        "Rotisería Central aprobó tu comprobante de pago correspondiente a octubre 2026.",
      ),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Cerrar notificación" }),
    ).toBeInTheDocument()
  })

  it("renders an order rejection notification with rejected title and reason and can be dismissed", () => {
    mocks.notifications.push({
      id: 99,
      title: "Tu pedido fue rechazado",
      description:
        "Tu pedido del 10 de octubre de Milanesa con puré fue rechazado por Tu Viandita porque no había stock disponible.",
      requires_action: false,
    })

    render(<NotificationBanners />)

    expect(screen.getByText("Tu pedido fue rechazado")).toBeInTheDocument()
    expect(
      screen.queryByText("Tu pedido fue cancelado"),
    ).not.toBeInTheDocument()
    expect(
      screen.getByText(
        "Tu pedido del 10 de octubre de Milanesa con puré fue rechazado por Tu Viandita porque no había stock disponible.",
      ),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Cerrar notificación" }),
    ).toBeInTheDocument()
  })

  it("renders a new order notification with updated quantity for provider and can be dismissed", async () => {
    const user = userEvent.setup()

    mocks.notifications.push({
      id: 77,
      title: "Nuevo pedido",
      description:
        "Juan Pérez pidió 3 de Milanesa con papas fritas para el viernes 6 de noviembre.",
      requires_action: false,
    })

    render(<NotificationBanners />)

    expect(screen.getByText("Nuevo pedido")).toBeInTheDocument()
    expect(
      screen.getByText(
        "Juan Pérez pidió 3 de Milanesa con papas fritas para el viernes 6 de noviembre.",
      ),
    ).toBeInTheDocument()

    const closeButton = screen.getByRole("button", {
      name: "Cerrar notificación",
    })
    await user.click(closeButton)

    expect(mocks.patch).toHaveBeenCalledWith(
      expect.objectContaining({
        url: "/notificaciones/77/cerrar",
        method: "patch",
      }),
      {},
      expect.objectContaining({
        preserveScroll: true,
      }),
    )
  })

  it("renders an HR debt payment reminder naming multiple creditors", () => {
    mocks.notifications.push({
      id: 2,
      title: "Recordatorio de pago pendiente",
      description:
        "Recursos Humanos te recuerda que tenés $950,75 en pagos vencidos con Tu Viandita y Endulzate. Podés verlos en tus pagos.",
      requires_action: false,
    })

    render(<NotificationBanners />)

    expect(
      screen.getByText("Recordatorio de pago pendiente"),
    ).toBeInTheDocument()
    expect(
      screen.getByText(
        "Recursos Humanos te recuerda que tenés $950,75 en pagos vencidos con Tu Viandita y Endulzate. Podés verlos en tus pagos.",
      ),
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
        url: "/notificaciones/42/cerrar",
        method: "patch",
      }),
      {},
      expect.objectContaining({
        preserveScroll: true,
      }),
    )
  })

  it("renders the dismissable alert icon with currentColor stroke to support dark mode", () => {
    mocks.notifications.push({
      id: 5,
      title: "Tu pedido fue cancelado",
      description: "Tu pedido no podrá ser entregado.",
      requires_action: false,
    })

    const { container } = render(<NotificationBanners />)

    const svg = container.querySelector("svg")
    expect(svg).toBeInTheDocument()

    const strokedElements = svg?.querySelectorAll("[stroke]") ?? []
    expect(strokedElements.length).toBeGreaterThan(0)

    strokedElements.forEach((el) => {
      expect(el.getAttribute("stroke")).toBe("currentColor")
      expect(el.getAttribute("stroke")).not.toBe("#0A0A0A")
    })
  })

  it("applies theme-adaptive classes on dark mode and keeps currentColor on dismissable alert icon", () => {
    document.documentElement.classList.add("dark")

    mocks.notifications.push({
      id: 6,
      title: "Notificación descartable en modo oscuro",
      description: "Descripción visible.",
      requires_action: false,
    })

    const { container } = render(<NotificationBanners />)

    const alert = container.querySelector("[role='alert']")
    expect(alert).toHaveClass("text-foreground")

    const svg = alert?.querySelector("svg")
    expect(svg).toBeInTheDocument()

    const strokedElements = svg?.querySelectorAll("[stroke]") ?? []
    strokedElements.forEach((el) => {
      expect(el.getAttribute("stroke")).toBe("currentColor")
    })

    document.documentElement.classList.remove("dark")
  })
})
