import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import { FileInput } from "./file-input"

describe("FileInput", () => {
  it("renders default button text and placeholder in Spanish", () => {
    render(<FileInput aria-label="Archivo" />)

    expect(screen.getByText("Seleccionar archivo")).toBeInTheDocument()
    expect(screen.getByText("Sin archivos seleccionados")).toBeInTheDocument()
  })

  it("renders the selected file name when provided", () => {
    render(
      <FileInput aria-label="Archivo" fileName="comprobante_octubre.pdf" />,
    )

    expect(screen.getByText("comprobante_octubre.pdf")).toBeInTheDocument()
    expect(
      screen.queryByText("Sin archivos seleccionados"),
    ).not.toBeInTheDocument()
  })

  it("forwards attributes to the hidden native file input", () => {
    render(
      <FileInput
        id="test-file-input"
        name="payment[receipt]"
        accept=".pdf,.png"
        disabled
      />,
    )

    const input =
      document.querySelector<HTMLInputElement>('input[type="file"]')!
    expect(input).toBeInTheDocument()
    expect(input).toHaveAttribute("id", "test-file-input")
    expect(input).toHaveAttribute("name", "payment[receipt]")
    expect(input).toHaveAttribute("accept", ".pdf,.png")
    expect(input).toBeDisabled()
  })

  it("triggers onChange when a file is selected", async () => {
    const user = userEvent.setup()
    const handleChange = vi.fn()
    render(<FileInput aria-label="Archivo" onChange={handleChange} />)

    const file = new File(["dummy content"], "factura.png", {
      type: "image/png",
    })
    const input = screen.getByLabelText("Archivo")
    await user.upload(input, file)

    expect(handleChange).toHaveBeenCalledTimes(1)
  })
})
