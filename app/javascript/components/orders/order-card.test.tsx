import { render, screen } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

import type { Order } from "@/types"

import OrderCard from "./order-card"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    usePage: () => ({ props: { locale: "es" } }),
    Link: ({
      children,
      href,
      ...props
    }: {
      children: React.ReactNode
      href: string | { url: string }
    }) => (
      <a href={typeof href === "string" ? href : href.url} {...props}>
        {children}
      </a>
    ),
  }
})

describe("OrderCard", () => {
  const baseOrder: Order = {
    id: 1,
    status: "pending",
    delivery_method: "home",
    amount: 1,
    notes: null,
    address: "Julio Herrera y Reissig 565",
    rejection_details: null,
    date: "2026-10-24",
    menu_name: "Milanesa con ensalada",
    provider_name: "TuViandita",
    price: 350,
    subsidy: 150,
    discounted_price: 200,
    cancellable: true,
    cancellation_block_reason: undefined,
    modifiable: true,
    modification_block_reason: undefined,
    reviewable: false,
    reviewed: false,
    selected_options: [],
  }

  describe("address rendering according to order status and section", () => {
    it("renders 'Lo pediste para:' for cancelled orders in history", () => {
      const cancelledOrder: Order = {
        ...baseOrder,
        status: "cancelled",
        cancellable: false,
        cancellation_block_reason: "already_closed",
      }

      render(<OrderCard order={cancelledOrder} section="history" />)

      expect(
        screen.getByText(/Lo pediste para: Julio Herrera y Reissig 565 \(Domicilio\)/i),
      ).toBeInTheDocument()
      expect(screen.queryByText(/Lo recibiste en:/i)).not.toBeInTheDocument()
    })

    it("renders 'Lo pediste para:' for rejected orders in history", () => {
      const rejectedOrder: Order = {
        ...baseOrder,
        status: "rejected",
        cancellable: false,
        cancellation_block_reason: "already_closed",
      }

      render(<OrderCard order={rejectedOrder} section="history" />)

      expect(
        screen.getByText(/Lo pediste para: Julio Herrera y Reissig 565 \(Domicilio\)/i),
      ).toBeInTheDocument()
      expect(screen.queryByText(/Lo recibiste en:/i)).not.toBeInTheDocument()
    })

    it("renders 'Lo recibiste en:' for confirmed orders in history", () => {
      const confirmedOrder: Order = {
        ...baseOrder,
        status: "confirmed",
        cancellable: false,
        cancellation_block_reason: "already_closed",
      }

      render(<OrderCard order={confirmedOrder} section="history" />)

      expect(
        screen.getByText(/Lo recibiste en: Julio Herrera y Reissig 565 \(Domicilio\)/i),
      ).toBeInTheDocument()
    })

    it("renders 'Lo recibís en:' for pending orders in upcoming section", () => {
      render(<OrderCard order={baseOrder} section="upcoming" />)

      expect(
        screen.getByText(/Lo recibís en: Julio Herrera y Reissig 565 \(Domicilio\)/i),
      ).toBeInTheDocument()
    })
  })

  describe("cancellation after order deadline has passed", () => {
    it("disables the cancel button and explains the deadline passed reason", () => {
      const closedOrder: Order = {
        ...baseOrder,
        status: "pending",
        cancellable: false,
        cancellation_block_reason: "order_deadline_passed",
      }

      render(<OrderCard order={closedOrder} section="upcoming" />)

      const cancelButton = screen.getByRole("button", { name: /Cancelar/i })
      expect(cancelButton).toBeDisabled()
      expect(
        screen.getByText(
          "El proveedor ya cerró la recepción de pedidos de hoy, así que no se puede cancelar.",
        ),
      ).toBeInTheDocument()
    })

    it("renders active cancel sheet button when order is cancellable", () => {
      render(<OrderCard order={baseOrder} section="upcoming" />)

      const cancelButton = screen.getByRole("button", { name: /Cancelar/i })
      expect(cancelButton).toBeEnabled()
      expect(
        screen.queryByText(
          "El proveedor ya cerró la recepción de pedidos de hoy, así que no se puede cancelar.",
        ),
      ).not.toBeInTheDocument()
    })
  })
})
