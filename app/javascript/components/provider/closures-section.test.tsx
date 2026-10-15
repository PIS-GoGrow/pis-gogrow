import { fireEvent, render, screen } from "@testing-library/react"
import type React from "react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import type { ProviderClosure } from "@/types/serializers/ProviderClosure"

import ClosuresSection from "./closures-section"

const routerDeleteMock = vi.fn()
let formErrorsMock: Record<string, string[]> = {}

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    router: {
      delete: (...args: unknown[]) => {
        routerDeleteMock(...args)
      },
    },
    Form: ({
      children,
      action,
      method,
    }: {
      children: (props: {
        errors: Record<string, string[]>
        processing: boolean
      }) => React.ReactNode
      action: string
      method: string
    }) => (
      <form action={action} method={method} data-testid="closure-form">
        {children({
          errors: formErrorsMock,
          processing: false,
        })}
      </form>
    ),
  }
})

describe("ClosuresSection", () => {
  const sampleClosures: ProviderClosure[] = [
    {
      id: 1,
      reason: "Vacaciones de invierno",
      starts_on: "2026-10-20",
      ends_on: "2026-10-22",
      period: "20 al 22 de octubre de 2026",
    },
    {
      id: 2,
      reason: "Feriado",
      starts_on: "2026-11-02",
      ends_on: "2026-11-02",
      period: "2 de noviembre de 2026",
    },
  ]

  beforeEach(() => {
    vi.clearAllMocks()
    formErrorsMock = {}
  })

  it("muestra el título y descripción de la sección de cierres", () => {
    render(<ClosuresSection closures={[]} today="2026-10-12" />)

    expect(screen.getByText("Cierres programados")).toBeInTheDocument()
    expect(
      screen.getByText("Días en los que no recibís pedidos."),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Programar cierre" }),
    ).toBeInTheDocument()
  })

  it("renderiza la lista de cierres con sus motivos y períodos", () => {
    render(<ClosuresSection closures={sampleClosures} today="2026-10-12" />)

    expect(screen.getByText("Vacaciones de invierno")).toBeInTheDocument()
    expect(screen.getByText("20 al 22 de octubre de 2026")).toBeInTheDocument()
    expect(screen.getByText("Feriado")).toBeInTheDocument()
    expect(screen.getByText("2 de noviembre de 2026")).toBeInTheDocument()
  })

  it("abre el formulario para programar un nuevo cierre al hacer clic en 'Programar cierre'", () => {
    render(<ClosuresSection closures={[]} today="2026-10-12" />)

    fireEvent.click(screen.getByRole("button", { name: "Programar cierre" }))

    expect(
      screen.getByRole("heading", { name: "Programar cierre" }),
    ).toBeInTheDocument()
    expect(screen.getByLabelText("Rango de fechas")).toBeInTheDocument()
    expect(screen.getByLabelText("Motivo")).toBeInTheDocument()
    expect(
      screen.getByRole("button", { name: "Guardar cambios" }),
    ).toBeInTheDocument()
  })

  it("abre el formulario para editar un cierre existente con sus valores previos", () => {
    render(<ClosuresSection closures={sampleClosures} today="2026-10-12" />)

    const editButtons = screen.getAllByRole("button", { name: /Editar cierre/ })
    fireEvent.click(editButtons[0])

    expect(
      screen.getByRole("heading", { name: "Editar cierre" }),
    ).toBeInTheDocument()
    expect(screen.getByLabelText("Motivo")).toHaveValue(
      "Vacaciones de invierno",
    )
  })

  it("invoca router.delete al confirmar la eliminación de un cierre", () => {
    render(<ClosuresSection closures={sampleClosures} today="2026-10-12" />)

    const deleteButtons = screen.getAllByRole("button", { name: /Eliminar cierre/ })
    fireEvent.click(deleteButtons[0])

    expect(routerDeleteMock).toHaveBeenCalledWith(
      expect.stringContaining("/provider/closures/1"),
      expect.objectContaining({ preserveScroll: true }),
    )
  })

  it("muestra errores de validación devueltos por el servidor", () => {
    formErrorsMock = {
      reason: ["Ingresá el motivo del cierre."],
      base: ["Ya tenés un cierre programado en esas fechas."],
    }
    render(<ClosuresSection closures={[]} today="2026-10-12" />)

    fireEvent.click(screen.getByRole("button", { name: "Programar cierre" }))

    expect(
      screen.getByText("Ingresá el motivo del cierre."),
    ).toBeInTheDocument()
    expect(
      screen.getByText("Ya tenés un cierre programado en esas fechas."),
    ).toBeInTheDocument()
  })
})
