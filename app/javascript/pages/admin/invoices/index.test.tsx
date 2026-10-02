import { render, screen, within } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import type { AdminInvoice } from "@/types/serializers"

import Index from "./index"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    // useFormatters saca el idioma de las props compartidas.
    usePage: () => ({ props: { locale: "es" } }),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

// Historia: "Como RRHH, quiero visualizar los recibos o facturas que el
// proveedor emite a GoGrow, para respaldar los pagos de la empresa y disponer
// de su historial."
describe("Admin::Invoices Index Page", () => {
  const invoice: AdminInvoice = {
    id: 7,
    status: "approved",
    period: "septiembre 2026",
    issued_on: "30/09/26",
    provider_name: "TuViandita",
    total_amount: 1250,
    period_amount: 1180,
    file_name: "factura.pdf",
    file_size: "320 KB",
  }

  it("shows the period, the provider and the invoiced total of each invoice", () => {
    render(<Index invoices={[invoice]} />)

    const row = screen.getByRole("row", { name: /TuViandita/ })
    expect(within(row).getByText("septiembre 2026")).toBeInTheDocument()
    expect(within(row).getByText("30/09/26")).toBeInTheDocument()
    expect(within(row).getByText("Aprobada")).toBeInTheDocument()
  })

  // Lo facturado y lo consumido en el período son datos distintos: RR. HH. los
  // compara para respaldar el pago, así que no se puede mostrar uno solo.
  it("shows what the period consumed next to what was invoiced", () => {
    render(<Index invoices={[invoice]} />)

    const row = screen.getByRole("row", { name: /TuViandita/ })
    expect(within(row).getByText(/1[.]?250/)).toBeInTheDocument()
    expect(within(row).getByText(/1[.]?180/)).toBeInTheDocument()
  })

  it("says so when the period has no consumption recorded", () => {
    render(<Index invoices={[{ ...invoice, period_amount: undefined }]} />)

    expect(screen.getByText("Sin consumo registrado")).toBeInTheDocument()
  })

  it("links to the file to open it and to download it", () => {
    render(<Index invoices={[invoice]} />)

    expect(screen.getByRole("link", { name: "Ver" })).toHaveAttribute(
      "href",
      "/admin/invoices/7/file",
    )
    expect(
      screen.getByRole("link", { name: "Descargar factura.pdf" }),
    ).toHaveAttribute("href", "/admin/invoices/7/file?download=1")
  })

  it("explains the empty state instead of showing an empty table", () => {
    render(<Index invoices={[]} />)

    expect(screen.getByText("Todavía no hay facturas")).toBeInTheDocument()
    expect(screen.queryByRole("table")).not.toBeInTheDocument()
  })
})
