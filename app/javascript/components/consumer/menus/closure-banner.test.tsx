import { fireEvent, render, screen } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

import type { ConsumerClosure } from "@/types"

import ClosureBanner from "./closure-banner"

describe("ClosureBanner", () => {
  const closure: ConsumerClosure = {
    id: 1,
    provider_id: 1,
    provider_name: "Tu Vianda SRL",
    period: "20/10/26 al 22/10/26",
    reason: "Vacaciones de invierno",
    starts_on: "2026-10-20",
    ends_on: "2026-10-22",
  }

  it("muestra el título correspondiente cuando el cierre está en curso ('now')", () => {
    render(<ClosureBanner closure={closure} when="now" />)

    expect(
      screen.getByText("Tu Vianda SRL no está disponible"),
    ).toBeInTheDocument()
    expect(
      screen.getByText(
        "Sus viandas no estarán disponibles del 20/10/26 al 22/10/26. Motivo: Vacaciones de invierno",
      ),
    ).toBeInTheDocument()
  })

  it("muestra el título correspondiente antes de que empiece el cierre ('soon')", () => {
    render(<ClosureBanner closure={closure} when="soon" />)

    expect(
      screen.getByText("Tu Vianda SRL no estará disponible"),
    ).toBeInTheDocument()
  })

  it("permite cerrar el aviso al hacer clic en el botón de descarte", () => {
    const onDismiss = vi.fn()
    render(<ClosureBanner closure={closure} when="now" onDismiss={onDismiss} />)

    const dismissButton = screen.getByRole("button", { name: "Cerrar aviso" })
    expect(dismissButton).toBeInTheDocument()

    fireEvent.click(dismissButton)
    expect(onDismiss).toHaveBeenCalledTimes(1)
  })

  it("no muestra botón de descarte si no se pasa onDismiss", () => {
    render(<ClosureBanner closure={closure} when="now" />)

    expect(
      screen.queryByRole("button", { name: "Cerrar aviso" }),
    ).not.toBeInTheDocument()
  })
})
