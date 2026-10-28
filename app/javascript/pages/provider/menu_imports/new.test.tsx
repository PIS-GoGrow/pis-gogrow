import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import type { ProviderMenuImportsNew } from "@/types"

import New from "./new"

// vi.mock se iza arriba de todo: sin vi.hoisted, la fábrica correría antes de
// que estos existan.
const { postMock, routerGet, routerPost } = vi.hoisted(() => ({
  postMock: vi.fn(),
  routerGet: vi.fn(),
  routerPost: vi.fn(),
}))
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
    router: { get: routerGet, post: routerPost },
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

const NO_AGENDA = {
  mode: "none" as const,
  weekdays: [],
  date: null,
  starts_on: null,
  ends_on: null,
  amount: null,
}

// Un plato tal como lo devuelve la vista previa, antes de que el proveedor
// toque nada.
function entry(
  number: number,
  name: string,
  values: Partial<{ price: number | null; errors: string[] }> = {},
) {
  return {
    number,
    name,
    description: `Descripción de ${name}`,
    price: 300,
    option_groups: [],
    errors: [],
    ...values,
  }
}

describe("Pantalla de importar platos", () => {
  const user = userEvent.setup()

  const props: ProviderMenuImportsNew = {
    template_path: "/plantillas/menu.xlsx",
    formats: [".xlsx", ".xls", ".csv", ".ods"],
    max_rows: 200,
    max_size_mb: 5,
    today: "2026-10-28",
    maximum_publish_date: "2026-12-31",
    saved_menus: [
      {
        id: 1,
        name: "Milanesa con papas fritas",
        confirmed_orders: 0,
        agenda: NO_AGENDA,
      },
    ],
    preview: null,
    imported: null,
    row_errors: {},
  }

  // La vista previa de una planilla con un plato nuevo, uno con error y uno
  // que el proveedor ya tiene guardado.
  const preview = {
    id: "abc123",
    filename: "platos.csv",
    error: null,
    entries: [
      entry(2, "Tarta de jamón y queso"),
      entry(3, "Budín de zanahoria", {
        price: null,
        errors: ["El precio tiene que ser un número mayor que cero."],
      }),
      entry(4, "Milanesa con papas fritas"),
    ],
  }

  beforeEach(() => {
    postMock.mockClear()
    routerPost.mockClear()
    currentFormData = { file: null }
  })

  it("muestra los dos pasos y el enlace para descargar la plantilla", () => {
    render(<New {...props} />)

    expect(screen.getByText("Descargá la plantilla")).toBeInTheDocument()
    expect(screen.getByText("Subí tu archivo")).toBeInTheDocument()
    expect(
      screen.getByText("Soporta XLSX, XLS, CSV, ODS hasta 5 MB"),
    ).toBeInTheDocument()

    const link = screen.getByRole("link", { name: "Descargar plantilla" })
    expect(link).toHaveAttribute("href", "/plantillas/menu.xlsx")
    expect(link).toHaveAttribute("download")
  })

  it("no deja subir hasta que se elige un archivo", () => {
    render(<New {...props} />)

    expect(screen.getByText("Sin archivos seleccionados")).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Subir archivo" })).toBeDisabled()
  })

  it("manda la planilla al tocar Subir archivo", async () => {
    currentFormData = { file: new File(["nombre"], "platos.csv") }
    render(<New {...props} />)

    await user.click(screen.getByRole("button", { name: "Subir archivo" }))

    expect(postMock).toHaveBeenCalledWith(
      "/proveedor/importar-platos",
      expect.objectContaining({ preserveState: true }),
    )
  })

  it("avisa cuando la planilla no se pudo leer", () => {
    render(
      <New
        {...props}
        preview={{
          ...preview,
          entries: [],
          error: "El archivo tiene que ser .xlsx, .xls, .csv o .ods.",
        }}
      />,
    )

    expect(screen.getByText("No se pudo leer la planilla")).toBeInTheDocument()
    expect(
      screen.getByText("El archivo tiene que ser .xlsx, .xls, .csv o .ods."),
    ).toBeInTheDocument()
    expect(screen.queryByText("Resumen")).not.toBeInTheDocument()
  })

  it("muestra una tarjeta por plato, con el estado de cada uno", () => {
    render(<New {...props} preview={preview} />)

    expect(screen.getByText("platos.csv")).toBeInTheDocument()
    expect(screen.getByText("1 Nuevo")).toBeInTheDocument()
    expect(screen.getByText("1 Error")).toBeInTheDocument()
    expect(screen.getByText("1 Ya existe")).toBeInTheDocument()

    expect(screen.getByText("Tarta de jamón y queso")).toBeInTheDocument()
    expect(
      screen.getByText("El precio tiene que ser un número mayor que cero."),
    ).toBeInTheDocument()
    expect(
      screen.getByText(
        "Este plato no se importará a menos que elijas una de las siguientes acciones.",
      ),
    ).toBeInTheDocument()
  })

  it("no deja importar mientras quede una fila con error", () => {
    render(<New {...props} preview={preview} />)

    expect(
      screen.getByRole("button", { name: "Importar platos" }),
    ).toBeDisabled()
    expect(
      screen.getByText(
        "Corregí o quitá los platos con error para poder importar.",
      ),
    ).toBeInTheDocument()
  })

  it("quitar la fila con error habilita la importación", async () => {
    render(<New {...props} preview={preview} />)

    // Dos tarjetas ofrecen "Quitar": la del plato nuevo y la del que tiene
    // error, que es la segunda.
    await user.click(screen.getAllByRole("button", { name: "Quitar" })[1])

    expect(screen.queryByText("Budín de zanahoria")).not.toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Importar platos" }),
    ).toBeEnabled()
  })

  it("manda la lista revisada al importar, sin el plato que ya existe", async () => {
    render(<New {...props} preview={preview} />)

    await user.click(screen.getAllByRole("button", { name: "Quitar" })[1])
    await user.click(screen.getByRole("button", { name: "Importar platos" }))

    expect(routerPost).toHaveBeenCalledOnce()
    const [url, payload] = routerPost.mock.calls[0] as [
      string,
      { preview_id: string; entries: { name: string }[] },
    ]
    expect(url).toBe("/proveedor/importar-platos/confirmar")
    expect(payload.preview_id).toBe("abc123")
    expect(payload.entries.map((it) => it.name)).toEqual([
      "Tarta de jamón y queso",
    ])
  })

  it("avisa cuando la importación terminó", () => {
    render(<New {...props} preview={preview} imported={{ count: 2 }} />)

    expect(screen.getByText("¡Platos importados!")).toBeInTheDocument()
  })

  it("al tocar Duplicar en un plato existente lo pasa a nuevo y actualiza el resumen", async () => {
    render(<New {...props} preview={preview} />)

    expect(screen.getByText("1 Nuevo")).toBeInTheDocument()
    expect(screen.getByText("1 Ya existe")).toBeInTheDocument()

    await user.click(screen.getByRole("button", { name: "Duplicar" }))

    expect(screen.getByText("2 Nuevos")).toBeInTheDocument()
    expect(screen.queryByText("1 Ya existe")).not.toBeInTheDocument()
  })

  it("al tocar Actualizar en un plato existente sin pedidos confirmados lo pasa a actualizado", async () => {
    render(<New {...props} preview={preview} />)

    expect(screen.getByText("1 Ya existe")).toBeInTheDocument()

    await user.click(screen.getByRole("button", { name: "Actualizar" }))

    expect(screen.getByText("1 Actualizado")).toBeInTheDocument()
    expect(screen.queryByText("1 Ya existe")).not.toBeInTheDocument()
  })
})
