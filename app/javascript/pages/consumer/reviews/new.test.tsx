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

  it.each(["a".repeat(200), "vianda ".repeat(29).slice(0, 200)])(
    "conserva el limite y el contador con una resena de 200 caracteres",
    (description) => {
      render(<New order={order} />)
      const textarea = document.getElementById(
        "description",
      ) as HTMLTextAreaElement
      expect(textarea.maxLength).toBe(200)
      fireEvent.change(textarea, { target: { value: description } })
      expect(textarea.value).toHaveLength(200)
      expect(screen.getByText("200/200")).toBeInTheDocument()
    },
  )

  it("mantiene una sola estrella seleccionada y envia su puntuacion", () => {
    render(<New order={order} />)
    const stars = screen.getAllByRole("radio")
    stars.forEach((star, index) => {
      fireEvent.click(star)
      expect(star).toHaveAttribute("aria-checked", "true")
      expect(
        stars.filter((item) => item.getAttribute("aria-checked") === "true"),
      ).toHaveLength(1)
      expect(document.querySelector('input[name="rating"]')).toHaveValue(
        String(index + 1),
      )
    })
  })

  it("muestra el plato antes del proveedor y la fecha sin coma", () => {
    render(<New order={order} />)
    const dish = screen.getByText("Sorrentinos")
    const subtitle = screen.getByText(/Endulzate by Noe/)
    expect(subtitle.textContent).not.toContain(",")
    expect(
      dish.compareDocumentPosition(subtitle) & Node.DOCUMENT_POSITION_FOLLOWING,
    ).toBeTruthy()
  })
})
