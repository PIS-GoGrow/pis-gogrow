import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import { providerMenuImports } from "@/routes"
import type { ProviderMenuImportsNew } from "@/types"

import New from "./new"

const postMock = vi.fn()
let currentFormData: { file: File | null } = { file: null }

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    Link: ({ children, href, ...props }: React.ComponentProps<"a">) => (
      <a href={href} {...props}>
        {children}
      </a>
    ),
    useForm: () => ({
      data: currentFormData,
      setData: (key: string, value: unknown) => {
        if (key === "file") currentFormData.file = value as File | null
      },
      post: postMock,
      processing: false,
    }),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

describe("Provider MenuImports New Page", () => {
  const user = userEvent.setup()

  const defaultProps: ProviderMenuImportsNew = {
    template_path: "/plantillas/menu.csv",
    max_rows: 200,
    max_size_mb: 2,
    preview: null,
  }

  beforeEach(() => {
    postMock.mockClear()
    currentFormData = { file: null }
  })

  it("muestra las instrucciones de importación y el enlace de descarga de plantilla", () => {
    render(<New {...defaultProps} />)

    expect(screen.getByText("Importar platos")).toBeInTheDocument()
    expect(screen.getByText(/Descargá la plantilla y abrila con Excel/)).toBeInTheDocument()
    expect(screen.getByText("Hasta 200 platos por planilla y 2 MB por archivo. Se aceptan .xlsx, .csv y .ods.")).toBeInTheDocument()

    const downloadLink = screen.getByRole("link", { name: "Descargar plantilla" })
    expect(downloadLink).toHaveAttribute("href", "/plantillas/menu.csv")
    expect(downloadLink).toHaveAttribute("download")
  })

  it("muestra el mensaje de ningún archivo seleccionado y deshabilita el botón de vista previa inicialmente", () => {
    render(<New {...defaultProps} />)

    expect(screen.getByText("Todavía no elegiste ningún archivo")).toBeInTheDocument()
    const previewBtn = screen.getByRole("button", { name: "Ver qué se va a importar" })
    expect(previewBtn).toBeDisabled()
    expect(screen.queryByRole("button", { name: "Confirmar importación" })).not.toBeInTheDocument()
  })

  it("muestra un error general del archivo cuando la vista previa falla a nivel de archivo", () => {
    const file = new File(["dummy"], "menu.csv", { type: "text/csv" })
    currentFormData = { file }

    render(
      <New
        {...defaultProps}
        preview={{
          error: "El archivo no se pudo abrir.",
          filename: "menu.csv",
          can_import: false,
          entries: [],
        }}
      />,
    )

    expect(screen.getByText("No se pudo leer la planilla")).toBeInTheDocument()
    expect(screen.getByText("El archivo no se pudo abrir.")).toBeInTheDocument()
    expect(screen.queryByRole("button", { name: "Confirmar importación" })).not.toBeInTheDocument()
  })

  it("muestra las filas a crear y actualizar con sus estados", () => {
    const file = new File(["dummy"], "menu.csv", { type: "text/csv" })
    currentFormData = { file }

    render(
      <New
        {...defaultProps}
        preview={{
          error: null,
          filename: "menu.csv",
          can_import: true,
          entries: [
            { number: 9, name: "Milanesa con papas", action: "update", errors: [] },
            { number: 10, name: "Sorrentinos", action: "create", errors: [] },
          ],
        }}
      />,
    )

    expect(screen.getByText("Vista previa")).toBeInTheDocument()
    expect(screen.getByText("1 para crear · 1 para actualizar")).toBeInTheDocument()
    expect(screen.getByText("Milanesa con papas")).toBeInTheDocument()
    expect(screen.getByText("Fila 9")).toBeInTheDocument()
    expect(screen.getByText("Actualiza")).toBeInTheDocument()

    expect(screen.getByText("Sorrentinos")).toBeInTheDocument()
    expect(screen.getByText("Fila 10")).toBeInTheDocument()
    expect(screen.getByText("Nuevo")).toBeInTheDocument()

    expect(screen.getByRole("button", { name: "Confirmar importación" })).toBeInTheDocument()
  })

  it("señala los errores específicos de cada fila y no permite confirmar cuando hay fallos", () => {
    const file = new File(["dummy"], "menu.csv", { type: "text/csv" })
    currentFormData = { file }

    render(
      <New
        {...defaultProps}
        preview={{
          error: null,
          filename: "menu.csv",
          can_import: false,
          entries: [
            {
              number: 3,
              name: "Tarta de verdura",
              action: "create",
              errors: ["El precio tiene que ser un número mayor que cero."],
            },
          ],
        }}
      />,
    )

    expect(screen.getByText("Tarta de verdura")).toBeInTheDocument()
    expect(screen.getByText("El precio tiene que ser un número mayor que cero.")).toBeInTheDocument()
    expect(screen.getByText("Hay que corregir la planilla")).toBeInTheDocument()
    expect(
      screen.getByText("No se importa ningún plato hasta que todas las filas estén bien."),
    ).toBeInTheDocument()
    expect(screen.queryByRole("button", { name: "Confirmar importación" })).not.toBeInTheDocument()
  })

  it("oculta la vista previa anterior si el usuario selecciona un archivo diferente", () => {
    const otherFile = new File(["dummy"], "otro_menu.csv", { type: "text/csv" })
    currentFormData = { file: otherFile }

    render(
      <New
        {...defaultProps}
        preview={{
          error: null,
          filename: "menu_viejo.csv",
          can_import: true,
          entries: [{ number: 2, name: "Milanesa", action: "create", errors: [] }],
        }}
      />,
    )

    expect(screen.queryByText("Vista previa")).not.toBeInTheDocument()
    expect(screen.queryByText("Milanesa")).not.toBeInTheDocument()
    expect(screen.queryByRole("button", { name: "Confirmar importación" })).not.toBeInTheDocument()
  })

  it("envía la confirmación al hacer click en Confirmar importación", async () => {
    const file = new File(["dummy"], "menu.csv", { type: "text/csv" })
    currentFormData = { file }

    render(
      <New
        {...defaultProps}
        preview={{
          error: null,
          filename: "menu.csv",
          can_import: true,
          entries: [{ number: 9, name: "Milanesa", action: "update", errors: [] }],
        }}
      />,
    )

    const confirmBtn = screen.getByRole("button", { name: "Confirmar importación" })
    await user.click(confirmBtn)

    expect(postMock).toHaveBeenCalledWith(
      providerMenuImports.confirm().url,
      expect.objectContaining({ preserveState: true, preserveScroll: true }),
    )
  })

  it("envía la solicitud de vista previa al hacer click en Ver qué se va a importar", async () => {
    const file = new File(["dummy"], "menu.csv", { type: "text/csv" })
    currentFormData = { file }

    render(<New {...defaultProps} />)

    const previewBtn = screen.getByRole("button", { name: "Ver qué se va a importar" })
    await user.click(previewBtn)

    expect(postMock).toHaveBeenCalledWith(
      providerMenuImports.create().url,
      expect.objectContaining({ preserveState: true, preserveScroll: true }),
    )
  })
})
