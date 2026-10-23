import { act, render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it, vi } from "vitest"

import type { Payment } from "@/types"

import PaymentReceiptDialog from "./payment-receipt-dialog"

let triggerSuccess: (() => void) | undefined
let triggerError: ((errors: Record<string, string[]>) => void) | undefined
let triggerBefore: (() => boolean) | undefined

interface MockFormProps {
  children?:
    | React.ReactNode
    | ((props: {
        errors: Record<string, string[]>
        processing: boolean
        progress: { percentage: number } | null
      }) => React.ReactNode)
  action?: string | { url?: string; method?: string }
  method?: string
  onBefore?: () => boolean
  onSuccess?: () => void
  onError?: (errors: Record<string, string[]>) => void
  className?: string
}

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Form: ({
      children,
      action,
      method,
      onBefore,
      onSuccess,
      onError,
      className,
      ...props
    }: MockFormProps & Record<string, unknown>) => {
      const actionUrl =
        typeof action === "string"
          ? action
          : typeof action === "object" && action !== null && "url" in action
            ? action.url
            : undefined

      if (
        actionUrl &&
        (actionUrl === "/comprobantes" ||
          actionUrl.endsWith("/comprobantes")) &&
        method !== "delete"
      ) {
        triggerBefore = onBefore
        triggerSuccess = onSuccess
        triggerError = onError
      }

      const content =
        typeof children === "function"
          ? children({
              errors: {},
              processing: false,
              progress: null,
            })
          : children

      return (
        <form
          action={actionUrl}
          method={method}
          className={className}
          data-testid="inertia-form"
          onSubmit={(e) => {
            e.preventDefault()
          }}
          {...props}
        >
          {content}
        </form>
      )
    },
  }
})

describe("PaymentReceiptDialog", () => {
  const createObjectURLMock = vi.fn(() => "blob:http://localhost/mock-preview")
  const revokeObjectURLMock = vi.fn(() => undefined)

  beforeEach(() => {
    vi.clearAllMocks()
    triggerSuccess = undefined
    triggerError = undefined
    triggerBefore = undefined
    URL.createObjectURL = createObjectURLMock
    URL.revokeObjectURL = revokeObjectURLMock
  })

  const submittedPayment: Payment = {
    id: 101,
    status: "submitted",
    created_at: "2026-10-01T12:00:00Z",
    receipt_uploaded_at: "01/10/2026",
    receipt_filename: "comprobante_banco_1.png",
    receipt_url: "/consumer/payments/101/receipt",
    receipt_content_type: "image/png",
    rejection_reason: null,
  }

  const rejectedPayment: Payment = {
    id: 102,
    status: "rejected",
    created_at: "2026-10-02T10:00:00Z",
    receipt_uploaded_at: "02/10/2026",
    receipt_filename: "comprobante_banco_2.pdf",
    receipt_url: "/consumer/payments/102/receipt",
    receipt_content_type: "application/pdf",
    rejection_reason: "Comprobante ilegible",
  }

  const approvedPayment: Payment = {
    id: 103,
    status: "approved",
    created_at: "2026-09-30T10:00:00Z",
    receipt_uploaded_at: "30/09/2026",
    receipt_filename: "comprobante_banco_3.jpg",
    receipt_url: "/consumer/payments/103/receipt",
    receipt_content_type: "image/jpeg",
    rejection_reason: null,
  }

  it("renders upload button and no receipt cards when payments list is empty", () => {
    render(<PaymentReceiptDialog accountId={42} payments={[]} />)

    expect(
      screen.getByRole("button", { name: "Subir comprobante de pago" }),
    ).toBeInTheDocument()
    expect(screen.queryByText(/comprobante_banco/)).not.toBeInTheDocument()
  })

  it("shows the upload button disabled with an explanation when uploadDisabled is set", () => {
    render(
      <PaymentReceiptDialog
        accountId={42}
        payments={[submittedPayment]}
        uploadDisabled
      />,
    )

    const button = screen.getByRole("button", {
      name: "Subir comprobante de pago",
    })
    expect(button).toBeDisabled()
    expect(button).toHaveAccessibleDescription(
      "Ya hay un comprobante en revisión. Podrás enviar otro cuando se resuelva.",
    )
  })

  it("does not open the upload dialog when clicking the button if uploadDisabled is set", async () => {
    const user = userEvent.setup()
    render(
      <PaymentReceiptDialog
        accountId={42}
        payments={[submittedPayment]}
        uploadDisabled
      />,
    )

    const button = screen.getByRole("button", {
      name: "Subir comprobante de pago",
    })
    await user.click(button)

    expect(
      screen.queryByRole("dialog", { name: "Subir comprobante" }),
    ).not.toBeInTheDocument()
  })

  it("renders multiple receipts with filenames, dates, links and status badges", () => {
    render(
      <PaymentReceiptDialog
        accountId={42}
        payments={[submittedPayment, rejectedPayment, approvedPayment]}
      />,
    )

    expect(screen.getByText("comprobante_banco_1.png")).toBeInTheDocument()
    expect(screen.getByText("comprobante_banco_2.pdf")).toBeInTheDocument()
    expect(screen.getByText("comprobante_banco_3.jpg")).toBeInTheDocument()

    const link1 = screen.getByText("comprobante_banco_1.png")
    expect(link1).toHaveAttribute("href", "/consumer/payments/101/receipt")

    expect(screen.getByText("En revisión")).toBeInTheDocument()
    expect(screen.getByText("Rechazado")).toBeInTheDocument()
    expect(screen.getByText("Aprobado")).toBeInTheDocument()
  })

  it("shows delete button for submitted and rejected receipts, but NOT for approved", () => {
    render(
      <PaymentReceiptDialog
        accountId={42}
        payments={[submittedPayment, rejectedPayment, approvedPayment]}
      />,
    )

    const deleteButtons = screen.getAllByRole("button", {
      name: "Eliminar comprobante",
    })
    expect(deleteButtons).toHaveLength(2)
  })

  it("asks for confirmation before deleting a receipt", async () => {
    const user = userEvent.setup()
    const destroyAction = vi.fn((paymentId: number) => ({
      url: `/admin/pagos/${paymentId}`,
      method: "delete" as const,
    }))

    render(
      <PaymentReceiptDialog
        accountId={42}
        createAction={{ url: "/admin/pagos", method: "post" }}
        destroyAction={destroyAction}
        payments={[submittedPayment, rejectedPayment, approvedPayment]}
      />,
    )

    expect(
      screen.queryByRole("dialog", { name: "¿Eliminar comprobante?" }),
    ).not.toBeInTheDocument()

    await user.click(
      screen.getAllByRole("button", { name: "Eliminar comprobante" })[0],
    )

    expect(
      screen.getByRole("dialog", { name: "¿Eliminar comprobante?" }),
    ).toBeInTheDocument()
    expect(
      screen.getByText(
        "Esta acción no se puede deshacer. Podés volver a subir el comprobante mientras el pago no esté aprobado.",
      ),
    ).toBeInTheDocument()
    expect(destroyAction).toHaveBeenCalledWith(submittedPayment.id)
    expect(screen.getByRole("button", { name: "Cancelar" })).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Eliminar" })).toBeInTheDocument()
  })

  it("can hide deletion actions without hiding receipt states", () => {
    render(
      <PaymentReceiptDialog
        accountId={42}
        allowDelete={false}
        payments={[submittedPayment, rejectedPayment, approvedPayment]}
      />,
    )

    expect(
      screen.queryByRole("button", { name: "Eliminar comprobante" }),
    ).not.toBeInTheDocument()
    expect(screen.getByText("En revisión")).toBeInTheDocument()
    expect(screen.getByText("Rechazado")).toBeInTheDocument()
    expect(screen.getByText("Aprobado")).toBeInTheDocument()
  })

  it("keeps uploading available when a receipt is approved", () => {
    render(<PaymentReceiptDialog accountId={42} payments={[approvedPayment]} />)

    expect(screen.getByText("comprobante_banco_3.jpg")).toBeInTheDocument()
    expect(screen.getByText("Aprobado")).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Subir comprobante de pago" }),
    ).toBeInTheDocument()
  })

  it("opens the upload dialog when clicking the main trigger button", async () => {
    const user = userEvent.setup()
    render(
      <PaymentReceiptDialog accountId={42} payments={[submittedPayment]} />,
    )

    await user.click(
      screen.getByRole("button", { name: "Subir comprobante de pago" }),
    )

    expect(
      screen.getByRole("dialog", { name: "Subir comprobante" }),
    ).toBeInTheDocument()
    expect(
      screen.getByText("Adjuntá el comprobante correspondiente a este pago."),
    ).toBeInTheDocument()
    expect(screen.getByLabelText("Comprobante")).toBeInTheDocument()
  })

  it("displays preview when an image file is selected", async () => {
    const user = userEvent.setup()
    render(<PaymentReceiptDialog accountId={42} payments={[]} />)

    await user.click(
      screen.getByRole("button", { name: "Subir comprobante de pago" }),
    )

    const fileInput = screen.getByLabelText("Comprobante")
    const testFile = new File(["dummy content"], "mi_comprobante.png", {
      type: "image/png",
    })

    await user.upload(fileInput, testFile)

    expect(createObjectURLMock).toHaveBeenCalledWith(testFile)
    const previewImg = screen.getByAltText("Vista previa del comprobante")
    expect(previewImg).toBeInTheDocument()
    expect(previewImg).toHaveAttribute(
      "src",
      "blob:http://localhost/mock-preview",
    )
    expect(screen.getByText("mi_comprobante.png")).toBeInTheDocument()
  })

  it("asks for the file next to the field instead of submitting without one", async () => {
    const user = userEvent.setup()
    render(<PaymentReceiptDialog accountId={42} payments={[]} />)

    await user.click(
      screen.getByRole("button", { name: "Subir comprobante de pago" }),
    )

    let submitted: boolean | undefined
    act(() => {
      submitted = triggerBefore?.()
    })

    expect(submitted).toBe(false)
    expect(
      screen.getByText("Seleccioná el archivo del comprobante."),
    ).toBeInTheDocument()

    await user.upload(
      screen.getByLabelText("Comprobante"),
      new File(["dummy content"], "mi_comprobante.png", { type: "image/png" }),
    )

    expect(
      screen.queryByText("Seleccioná el archivo del comprobante."),
    ).not.toBeInTheDocument()
    expect(triggerBefore?.()).toBe(true)
  })

  it("shows success sheet when upload succeeds", async () => {
    const user = userEvent.setup()
    render(<PaymentReceiptDialog accountId={42} payments={[]} />)

    await user.click(
      screen.getByRole("button", { name: "Subir comprobante de pago" }),
    )

    expect(triggerSuccess).toBeDefined()
    act(() => {
      triggerSuccess?.()
    })

    expect(await screen.findByText("Comprobante enviado")).toBeInTheDocument()
    expect(
      screen.getByText(
        "Tu comprobante fue enviado correctamente y está pendiente de revisión.",
      ),
    ).toBeInTheDocument()

    const okButton = screen.getByRole("button", { name: "Listo" })
    expect(okButton).toBeInTheDocument()
    await user.click(okButton)

    expect(screen.queryByText("Comprobante enviado")).not.toBeInTheDocument()
  })

  it("shows error sheet when upload fails", async () => {
    const user = userEvent.setup()
    render(<PaymentReceiptDialog accountId={42} payments={[]} />)

    await user.click(
      screen.getByRole("button", { name: "Subir comprobante de pago" }),
    )

    expect(triggerError).toBeDefined()
    act(() => {
      triggerError?.({})
    })

    expect(
      await screen.findByText("No se pudo subir el comprobante"),
    ).toBeInTheDocument()
    expect(
      screen.getByText(
        "Ocurrió un problema al subir el archivo. Intentá nuevamente.",
      ),
    ).toBeInTheDocument()

    const retryButton = screen.getByRole("button", { name: "Entendido" })
    expect(retryButton).toBeInTheDocument()
    await user.click(retryButton)

    expect(
      screen.queryByText("No se pudo subir el comprobante"),
    ).not.toBeInTheDocument()
  })

  it("shows the server's reason when the receipt is rejected", async () => {
    const user = userEvent.setup()
    render(<PaymentReceiptDialog accountId={42} payments={[]} />)

    await user.click(
      screen.getByRole("button", { name: "Subir comprobante de pago" }),
    )

    act(() => {
      triggerError?.({ receipt: ["El archivo debe ser PDF, JPG o PNG."] })
    })

    expect(
      await screen.findByText("El archivo debe ser PDF, JPG o PNG."),
    ).toBeInTheDocument()
    expect(
      screen.queryByText(
        "Ocurrió un problema al subir el archivo. Intentá nuevamente.",
      ),
    ).not.toBeInTheDocument()
  })
})
