import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it, vi } from "vitest"

import {
  AdaptableDialog,
  AdaptableDialogClose,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogFooter,
  AdaptableDialogHeader,
  AdaptableDialogTitle,
  AdaptableDialogTrigger,
} from "./adaptable-dialog"

const mockUseIsMobile = vi.fn<() => boolean>(() => false)

vi.mock("@/hooks/use-mobile", () => ({
  useIsMobile: () => mockUseIsMobile(),
}))

describe("AdaptableDialog", () => {
  beforeEach(() => {
    vi.clearAllMocks()
    mockUseIsMobile.mockReturnValue(false)
  })

  function TestDialog({
    desktopVariant = "dialog",
    open,
    onOpenChange,
    defaultOpen,
  }: {
    desktopVariant?: "dialog" | "sheet"
    open?: boolean
    onOpenChange?: (open: boolean) => void
    defaultOpen?: boolean
  }) {
    return (
      <AdaptableDialog
        desktopVariant={desktopVariant}
        open={open}
        onOpenChange={onOpenChange}
        defaultOpen={defaultOpen}
      >
        <AdaptableDialogTrigger asChild>
          <button type="button">Abrir diálogo</button>
        </AdaptableDialogTrigger>
        <AdaptableDialogContent>
          <AdaptableDialogHeader>
            <AdaptableDialogTitle>Título del diálogo</AdaptableDialogTitle>
            <AdaptableDialogDescription>
              Descripción del diálogo
            </AdaptableDialogDescription>
          </AdaptableDialogHeader>
          <div>Cuerpo del modal</div>
          <AdaptableDialogFooter>
            <AdaptableDialogClose asChild>
              <button type="button">Cerrar</button>
            </AdaptableDialogClose>
          </AdaptableDialogFooter>
        </AdaptableDialogContent>
      </AdaptableDialog>
    )
  }

  it("renders trigger and opens dialog on click in desktop mode", async () => {
    const user = userEvent.setup()
    render(<TestDialog />)

    expect(screen.getByRole("button", { name: "Abrir diálogo" })).toBeInTheDocument()
    expect(screen.queryByText("Título del diálogo")).not.toBeInTheDocument()

    await user.click(screen.getByRole("button", { name: "Abrir diálogo" }))

    expect(screen.getByRole("dialog")).toBeInTheDocument()
    expect(screen.getByText("Título del diálogo")).toBeInTheDocument()
    expect(screen.getByText("Descripción del diálogo")).toBeInTheDocument()
    expect(screen.getByText("Cuerpo del modal")).toBeInTheDocument()
  })

  it("closes dialog when clicking close button", async () => {
    const user = userEvent.setup()
    render(<TestDialog defaultOpen />)

    expect(screen.getByRole("dialog")).toBeInTheDocument()

    await user.click(screen.getByRole("button", { name: "Cerrar" }))

    expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
  })

  it("supports controlled open state and calls onOpenChange", async () => {
    const user = userEvent.setup()
    const onOpenChange = vi.fn()
    render(<TestDialog open={false} onOpenChange={onOpenChange} />)

    await user.click(screen.getByRole("button", { name: "Abrir diálogo" }))
    expect(onOpenChange).toHaveBeenCalledWith(true)
  })

  it("renders as sheet in desktop when desktopVariant='sheet'", () => {
    mockUseIsMobile.mockReturnValue(false)
    render(<TestDialog desktopVariant="sheet" defaultOpen />)

    const content = screen.getByRole("dialog")
    expect(content).toBeInTheDocument()
    expect(screen.getByText("Título del diálogo")).toBeInTheDocument()
  })

  it("renders as bottom sheet when on mobile", () => {
    mockUseIsMobile.mockReturnValue(true)
    render(<TestDialog defaultOpen />)

    const dialog = screen.getByRole("dialog")
    expect(dialog).toBeInTheDocument()
    expect(dialog.className).toContain("rounded-t-xl")
  })

  it("throws an error when subcomponents are rendered outside of AdaptableDialog", () => {
    // Suppress React error boundary console log for this test
    const consoleSpy = vi.spyOn(console, "error").mockReturnValue()

    expect(() => render(<AdaptableDialogTitle>Inválido</AdaptableDialogTitle>)).toThrow(
      "Los componentes AdaptableDialog* deben usarse dentro de <AdaptableDialog>",
    )

    consoleSpy.mockRestore()
  })
})
