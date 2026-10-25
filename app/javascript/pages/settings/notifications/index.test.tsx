import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import { consumerProfiles } from "@/routes"

import Notifications from "./index"

const { patchMock, roleMock } = vi.hoisted(() => ({
  patchMock: vi.fn(),
  roleMock: { value: "admin" },
}))

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    router: { patch: patchMock },
    usePage: () => ({
      props: { auth: { session: { role: roleMock.value } } },
    }),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div>{children}</div>
  ),
}))

vi.mock("@/layouts/settings/page-layout", () => ({
  default: ({
    children,
    consumerMobileBackHref,
    consumerMobileBackLabel,
  }: {
    children: React.ReactNode
    consumerMobileBackHref?: string
    consumerMobileBackLabel?: string
  }) => (
    <div>
      {consumerMobileBackHref && (
        <a href={consumerMobileBackHref}>{consumerMobileBackLabel}</a>
      )}
      {children}
    </div>
  ),
}))

describe("Notification preferences", () => {
  beforeEach(() => {
    roleMock.value = "admin"
  })

  it("shows the existing and newly approved categories", () => {
    render(<Notifications {...props()} />)

    expect(screen.getByText("Preferencias de RR. HH.")).toBeInTheDocument()
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
      "/configuracion/notificaciones/2",
      { subscribe: true },
      expect.objectContaining({ preserveScroll: true, preserveState: true }),
    )
  })

  it("links mobile consumers back to their account", () => {
    roleMock.value = "consumer"

    render(<Notifications {...props()} />)

    expect(
      screen.getByRole("link", { name: "Volver a Mi cuenta" }),
    ).toHaveAttribute("href", consumerProfiles.show().url)
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
