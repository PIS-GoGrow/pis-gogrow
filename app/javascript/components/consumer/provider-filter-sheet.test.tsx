import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import { ProviderFilterSheet } from "./provider-filter-sheet"

describe("ProviderFilterSheet", () => {
  const providers = [
    { id: 1, name: "TuViandita" },
    { id: 2, name: "Chef Express" },
    { id: 3, name: "La Cocina" },
  ]

  it("renders trigger button", () => {
    render(
      <ProviderFilterSheet
        providers={providers}
        selectedProviders={new Set<number>()}
        onApply={vi.fn()}
      />,
    )

    expect(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    ).toBeInTheDocument()
  })

  it("opens filter sheet and displays providers and 'Todos'", async () => {
    const user = userEvent.setup()
    render(
      <ProviderFilterSheet
        providers={providers}
        selectedProviders={new Set<number>()}
        onApply={vi.fn()}
      />,
    )

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )

    expect(screen.getByText("Filtrar por proveedores")).toBeInTheDocument()
    expect(screen.getByLabelText("Todos")).toBeInTheDocument()
    providers.forEach((provider) => {
      expect(screen.getByLabelText(provider.name)).toBeInTheDocument()
    })
  })

  it("applies provider filter when selecting a provider and clicking Aplicar", async () => {
    const user = userEvent.setup()
    const onApply = vi.fn()

    render(
      <ProviderFilterSheet
        providers={providers}
        selectedProviders={new Set<number>()}
        onApply={onApply}
      />,
    )

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )

    await user.click(screen.getByLabelText("TuViandita"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expect(onApply).toHaveBeenCalledWith(new Set([1]))
    expect(
      screen.queryByText("Filtrar por proveedores"),
    ).not.toBeInTheDocument()
  })

  it("resets filter when clicking 'Todos' and applying", async () => {
    const user = userEvent.setup()
    const onApply = vi.fn()

    render(
      <ProviderFilterSheet
        providers={providers}
        selectedProviders={new Set([1])}
        onApply={onApply}
      />,
    )

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )

    await user.click(screen.getByLabelText("Todos"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expect(onApply).toHaveBeenCalledWith(new Set())
  })

  it("discards changes when clicking Cancelar", async () => {
    const user = userEvent.setup()
    const onApply = vi.fn()

    render(
      <ProviderFilterSheet
        providers={providers}
        selectedProviders={new Set<number>()}
        onApply={onApply}
      />,
    )

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )

    await user.click(screen.getByLabelText("TuViandita"))
    await user.click(screen.getByRole("button", { name: "Cancelar" }))

    expect(onApply).not.toHaveBeenCalled()
  })
})
