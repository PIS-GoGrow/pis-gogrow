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
      "/rrhh/facturas/7/archivo/factura.pdf",
    )
    expect(screen.getByRole("link", { name: "Ver" })).toHaveAttribute(
      "target",
      "_blank",
    )
    expect(screen.getByRole("link", { name: "Ver" })).toHaveAttribute(
      "rel",
      "noreferrer",
    )
    expect(
      screen.getByRole("link", { name: "Descargar factura.pdf" }),
    ).toHaveAttribute("href", "/rrhh/facturas/7/archivo?download=1")
  })

  it("encodes file names with spaces and special characters in the view URL", () => {
    const invoiceWithSpecialName: AdminInvoice = {
      ...invoice,
      id: 8,
      file_name: "factura agosto 2026 (1).pdf",
    }

    render(<Index invoices={[invoiceWithSpecialName]} />)

    expect(screen.getByRole("link", { name: "Ver" })).toHaveAttribute(
      "href",
      "/rrhh/facturas/8/archivo/factura%20agosto%202026%20(1).pdf",
    )
  })

  it("links each invoice in a list to its own file name", () => {
    const secondInvoice: AdminInvoice = {
      ...invoice,
      id: 9,
      provider_name: "Endulzate",
      file_name: "factura-endulzate.pdf",
    }

    render(<Index invoices={[invoice, secondInvoice]} />)

    const viewLinks = screen.getAllByRole("link", { name: "Ver" })
    expect(viewLinks).toHaveLength(2)
    expect(viewLinks[0]).toHaveAttribute(
      "href",
      "/rrhh/facturas/7/archivo/factura.pdf",
    )
    expect(viewLinks[1]).toHaveAttribute(
      "href",
      "/rrhh/facturas/9/archivo/factura-endulzate.pdf",
    )
  })

  it("explains the empty state instead of showing an empty table", () => {
    render(<Index invoices={[]} />)

    expect(screen.getByText("Todavía no hay facturas")).toBeInTheDocument()
    expect(screen.queryByRole("table")).not.toBeInTheDocument()
  })
})
