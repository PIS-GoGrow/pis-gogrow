import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it } from "vitest"

import type { ProviderCollectionPayment } from "@/types"

import CollectionPaymentHistory from "./collection-payment-history"

function payment(
  overrides: Partial<ProviderCollectionPayment> = {},
): ProviderCollectionPayment {
  return {
    id: 1,
    status: "approved",
    rejection_reason: null,
    date: "02/10/26",
    receipt_url: "/provider/payments/1/receipt",
    receipt_filename: "aprobado.png",
    receipt_content_type: "image/png",
    ...overrides,
  }
}

const approved = payment()
const rejected = payment({
  id: 2,
  status: "rejected",
  date: "30/09/26",
  receipt_url: "/provider/payments/2/receipt",
  receipt_filename: "rechazado.pdf",
  receipt_content_type: "application/pdf",
})
const withoutReceipt = payment({
  id: 3,
  receipt_url: null,
  receipt_filename: null,
  receipt_content_type: null,
})

describe("CollectionPaymentHistory", () => {
  it("renders nothing without payments", () => {
    const { container } = render(<CollectionPaymentHistory payments={[]} />)

    expect(container).toBeEmptyDOMElement()
  })

  it("renders nothing when no payment has a receipt", () => {
    const { container } = render(
      <CollectionPaymentHistory payments={[withoutReceipt]} />,
    )

    expect(container).toBeEmptyDOMElement()
  })

  it("offers a single download link for one receipt", () => {
    render(<CollectionPaymentHistory payments={[approved, withoutReceipt]} />)

    const link = screen.getByRole("link", { name: "Descargar comprobante" })

    expect(link).toHaveAttribute("href", "/provider/payments/1/receipt")
    expect(link).toHaveAttribute("download")
    expect(screen.getAllByRole("link")).toHaveLength(1)
  })

  it("lists every receipt directly when showDownloadAll is false", () => {
    render(
      <CollectionPaymentHistory
        payments={[approved, rejected, withoutReceipt]}
      />,
    )

    expect(screen.getByText("aprobado.png")).toBeInTheDocument()
    expect(screen.getByText("rechazado.pdf")).toBeInTheDocument()
  })

  it("lists every receipt with its date, status and file under 'Ver comprobantes' when showDownloadAll is true", async () => {
    const user = userEvent.setup()
    render(
      <CollectionPaymentHistory
        payments={[approved, rejected, withoutReceipt]}
        showDownloadAll
      />,
    )

    expect(screen.queryByText("aprobado.png")).not.toBeInTheDocument()

    await user.click(screen.getByRole("button", { name: "Ver comprobantes" }))

    const approvedLink = screen.getByRole("link", {
      name: "Descargar aprobado.png",
    })
    const rejectedLink = screen.getByRole("link", {
      name: "Descargar rechazado.pdf",
    })

    expect(approvedLink).toHaveAttribute("href", "/provider/payments/1/receipt")
    expect(approvedLink).toHaveAttribute("download")
    expect(rejectedLink).toHaveAttribute("href", "/provider/payments/2/receipt")
    expect(screen.getAllByRole("link")).toHaveLength(2)

    const approvedEntry = approvedLink.closest<HTMLElement>("div.grid")!
    expect(within(approvedEntry).getByText("02/10/26")).toBeInTheDocument()
    expect(within(approvedEntry).getByText("Confirmado")).toBeInTheDocument()

    const rejectedEntry = rejectedLink.closest<HTMLElement>("div.grid")!
    expect(within(rejectedEntry).getByText("30/09/26")).toBeInTheDocument()
    expect(within(rejectedEntry).getByText("Rechazado")).toBeInTheDocument()
  })

  it("shows partial payment badge when rejection reason is partial payment", () => {
    const partialPayment = payment({
      id: 4,
      status: "rejected",
      rejection_reason: "El pago es parcial",
      date: "01/10/26",
      receipt_url: "/provider/payments/4/receipt",
      receipt_filename: "parcial.png",
    })

    render(<CollectionPaymentHistory payments={[partialPayment, approved]} />)

    expect(screen.getByText("Pago parcial")).toBeInTheDocument()
  })
})
