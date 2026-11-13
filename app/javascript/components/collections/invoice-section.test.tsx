import { router } from "@inertiajs/react"
import { render, screen, waitFor, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, describe, expect, it, vi } from "vitest"

import type { ProviderCollectionAccount } from "@/types"

import InvoiceSection from "./invoice-section"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")

  return {
    ...actual,
    usePage: () => ({ props: { locale: "es" } }),
  }
})

const historicalCompanyAccount = {
  id: 1,
  owner_name: "GoGrow",
  meals: 10,
  amount: 30_000,
  vat_rate: 0.22,
  vat_amount: 6_600,
  payable_amount: 36_600,
  outstanding_amount: 36_600,
  expected_amount: null,
  source: "company",
  status: "approved",
  can_approve_payment: false,
  overdue: false,
  debt_reminder: {
    eligible: false,
    remaining: 0,
    next_available_at: null,
    blocked_reason: null,
  },
  month: "Septiembre 2026",
  month_name: "septiembre",
  due_date: "05/10/26",
  paid_on: "05/09/26",
  payment_id: 10,
  receipt_url: "/provider/comprobantes/10/archivo",
  receipt_content_type: "application/pdf",
  invoice: {
    id: 42,
    status: "approved",
    removable: false,
    total_amount: 30_000,
    issued_on: "05/09/26",
    file_name: "factura-septiembre.pdf",
    file_size: "120 KB",
  },
  orders: [],
  payments: [],
} satisfies ProviderCollectionAccount

describe("InvoiceSection", () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it("uses the company payable amount as the suggested invoice total", async () => {
    const user = userEvent.setup()
    const account = {
      ...historicalCompanyAccount,
      status: "pending",
      invoice: null,
    } satisfies ProviderCollectionAccount

    render(<InvoiceSection account={account} />)

    await user.upload(
      screen.getByLabelText("Archivo de la factura"),
      new File(["invoice"], "factura.pdf", { type: "application/pdf" }),
    )
    await user.click(screen.getByRole("button", { name: "Subir factura" }))

    expect(screen.getByLabelText("Monto total")).toHaveValue(36_600)
    expect(screen.getByText(/\$36\.600/)).toBeInTheDocument()
  })

  it("clears the previous file error when reopening the dialog with a new file", async () => {
    const user = userEvent.setup({ applyAccept: false })
    const fileError = "El archivo debe ser PDF, JPG o PNG."
    const account = {
      ...historicalCompanyAccount,
      status: "pending",
      invoice: null,
    } satisfies ProviderCollectionAccount

    // El servidor rechaza el envío: Inertia entrega los errores a useForm.
    vi.spyOn(router, "post").mockImplementation((...args: unknown[]) => {
      const options = args[2] as {
        onError?: (errors: Record<string, string[]>) => void
      }
      options.onError?.({ file: [fileError] })
    })

    render(<InvoiceSection account={account} />)

    await user.upload(
      screen.getByLabelText("Archivo de la factura"),
      new File(["texto"], "no-admitido.txt", { type: "text/plain" }),
    )
    await user.click(screen.getByRole("button", { name: "Subir factura" }))
    await user.click(
      within(screen.getByRole("dialog")).getByRole("button", {
        name: "Subir factura",
      }),
    )

    expect(screen.getByText(fileError)).toBeInTheDocument()

    await user.click(screen.getByRole("button", { name: "Cancelar" }))
    await waitFor(() =>
      expect(screen.queryByRole("dialog")).not.toBeInTheDocument(),
    )

    await user.upload(
      screen.getByLabelText("Archivo de la factura"),
      new File(["factura"], "factura.pdf", { type: "application/pdf" }),
    )
    await user.click(screen.getByRole("button", { name: "Subir factura" }))

    expect(screen.getByRole("dialog")).toBeInTheDocument()
    expect(screen.queryByText(fileError)).not.toBeInTheDocument()
  })

  it("shows the invoice download in collection history", () => {
    render(<InvoiceSection account={historicalCompanyAccount} settled />)

    expect(
      screen.getByRole("link", { name: "Descargar factura" }),
    ).toHaveAttribute("href", "/proveedor/facturas/42/archivo?download=1")
  })
})
