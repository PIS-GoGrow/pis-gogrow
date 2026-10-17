import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import Notifications from "./index"

const { patchMock } = vi.hoisted(() => ({ patchMock: vi.fn() }))

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    router: { patch: patchMock },
    usePage: () => ({ props: { auth: { session: { role: "admin" } } } }),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div>{children}</div>
  ),
}))

vi.mock("@/layouts/settings/page-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div>{children}</div>
  ),
}))

describe("RRHH notification preferences", () => {
  it("shows the existing and newly approved categories", () => {
    render(<Notifications {...props()} />)

    expect(screen.getByText("Preferencias de RRHH")).toBeInTheDocument()
    for (const title of [
      "Pagos a proveedores",
      "Pagos pendientes",
      "Comprobantes rechazados",
      "Pagos parciales",
      "Facturas pendientes",
      "Cambios en subsidios",
    ]) {
      expect(screen.getByRole("switch", { name: title })).toBeInTheDocument()
    }
  })

  it("saves a changed preference through the existing endpoint", async () => {
    const user = userEvent.setup()
    render(<Notifications {...props()} />)

    await user.click(screen.getByRole("switch", { name: "Pagos pendientes" }))

    expect(patchMock).toHaveBeenCalledWith(
      "/settings/notifications/2",
      { subscribe: true },
      expect.objectContaining({ preserveScroll: true, preserveState: true }),
    )
  })
})

function props() {
  return {
    notification_configurations: [
      configuration(1, "company_payments", "Pagos a proveedores"),
      configuration(2, "hr_pending_payments", "Pagos pendientes"),
      configuration(3, "hr_rejected_receipts", "Comprobantes rechazados"),
      configuration(4, "hr_partial_payments", "Pagos parciales"),
      configuration(5, "hr_pending_invoices", "Facturas pendientes"),
      configuration(6, "hr_subsidy_changes", "Cambios en subsidios"),
    ],
    subscribed_keys: ["company_payments"] as [string],
  }
}

function configuration(id: number, key: string, title: string) {
  return { id, key, title, description: `Descripción de ${title}` }
}
