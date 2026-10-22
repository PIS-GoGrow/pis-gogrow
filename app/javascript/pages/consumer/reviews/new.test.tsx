import { fireEvent, render, screen } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

import type { Order } from "@/types"

import New from "./new"

vi.mock("@inertiajs/react", () => ({
  Head: () => null,
  usePage: () => ({ props: { locale: "es" } }),
  Link: ({ children }: { children: React.ReactNode }) => <a>{children}</a>,
  Form: ({
    children,
  }: {
    action: unknown
    children: (props: {
      processing: boolean
      errors: Record<string, string[]>
    }) => React.ReactNode
  }) => <form>{children({ processing: false, errors: {} })}</form>,
}))

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

const order = {
  id: 1,
  menu_name: "Sorrentinos",
  provider_name: "Endulzate by Noe",
  date: "2026-09-10",
} as Order

describe("Consumer::Reviews New Page", () => {
  it("muestra el plato y mantiene Enviar deshabilitado hasta elegir puntuación", () => {
    render(<New order={order} />)

    expect(screen.getByText("Sorrentinos")).toBeInTheDocument()

    const submit = screen.getByRole("button", { name: "Enviar" })
    expect(submit).toBeDisabled()

    fireEvent.click(screen.getByRole("radio", { name: "3 estrellas" }))
    expect(submit).toBeEnabled()
  })

  it("actualiza el contador de caracteres de la reseña", () => {
    render(<New order={order} />)

    const textarea = document.getElementById(
      "description",
    ) as HTMLTextAreaElement
    expect(screen.getByText("0/200")).toBeInTheDocument()

    fireEvent.change(textarea, { target: { value: "Muy rico" } })
    expect(screen.getByText("8/200")).toBeInTheDocument()
  })
})
