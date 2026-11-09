import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import { ProviderFilterSheet } from "./provider-filter-sheet"

describe("ProviderFilterSheet", () => {
  it("applies the first and last providers of a long list together and can clear them", async () => {
    const user = userEvent.setup()
    const onApply = vi.fn()
    const manyProviders = Array.from({ length: 40 }, (_, i) => ({
      id: i + 1,
      name: `Proveedor ${i + 1}`,
    }))
    const { rerender } = render(
      <ProviderFilterSheet
        providers={manyProviders}
        selectedProviders={new Set([1])}
        onApply={onApply}
      />,
    )
    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Proveedor 40"))
    expect(screen.getByLabelText("Todos")).not.toBeChecked()
    await user.click(screen.getByRole("button", { name: "Aplicar" }))
    expect(onApply).toHaveBeenLastCalledWith(new Set([1, 40]))

    rerender(
      <ProviderFilterSheet
        providers={manyProviders}
        selectedProviders={new Set([1, 40])}
        onApply={onApply}
      />,
    )
    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    expect(screen.getByLabelText("Proveedor 1")).toBeChecked()
    expect(screen.getByLabelText("Proveedor 40")).toBeChecked()
    await user.click(screen.getByLabelText("Todos"))
    expect(screen.getByLabelText("Todos")).toBeChecked()
    expect(screen.getByLabelText("Proveedor 1")).toBeChecked()
    expect(screen.getByLabelText("Proveedor 40")).toBeChecked()
    await user.click(screen.getByRole("button", { name: "Aplicar" }))
    expect(onApply).toHaveBeenLastCalledWith(new Set())
  })

  const providers = [
    { id: 1, name: "TuViandita" },
    { id: 2, name: "Chef Express" },
    { id: 3, name: "La Cocina" },
  ]

  it.each([0, 1, 3])(
    "represents unrestricted selection with %i available providers",
    async (count) => {
      const user = userEvent.setup()
      const onApply = vi.fn()
      render(
        <ProviderFilterSheet
          providers={providers.slice(0, count)}
          selectedProviders={new Set<number>()}
          onApply={onApply}
        />,
      )
      await user.click(
        screen.getByRole("button", { name: "Filtrar por proveedores" }),
      )
      screen
        .getAllByRole("checkbox")
        .forEach((checkbox) => expect(checkbox).toBeChecked())
      if (count === 1) {
        await user.click(screen.getByLabelText("TuViandita"))
        screen
          .getAllByRole("checkbox")
          .forEach((checkbox) => expect(checkbox).toBeChecked())
      }
      await user.click(screen.getByRole("button", { name: "Aplicar" }))
      expect(onApply).toHaveBeenCalledWith(new Set())
    },
  )

  it("marks Todos after manually selecting every ID and includes newly available providers after applying", async () => {
    const user = userEvent.setup()
    const onApply = vi.fn()
    const { rerender } = render(
      <ProviderFilterSheet
        providers={providers}
        selectedProviders={new Set([1])}
        onApply={onApply}
      />,
    )
    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Chef Express"))
    expect(screen.getByLabelText("Todos")).not.toBeChecked()
    await user.click(screen.getByLabelText("La Cocina"))
    expect(screen.getByLabelText("Todos")).toBeChecked()
    await user.click(screen.getByRole("button", { name: "Aplicar" }))
    expect(onApply).toHaveBeenLastCalledWith(new Set())
    rerender(
      <ProviderFilterSheet
        providers={[...providers, { id: 4, name: "Nuevo proveedor" }]}
        selectedProviders={new Set<number>()}
        onApply={onApply}
      />,
    )
    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    screen
      .getAllByRole("checkbox")
      .forEach((checkbox) => expect(checkbox).toBeChecked())
    await user.click(screen.getByLabelText("Chef Express"))
    expect(screen.getByLabelText("Todos")).not.toBeChecked()
    await user.click(screen.getByRole("button", { name: "Aplicar" }))
    expect(onApply).toHaveBeenLastCalledWith(new Set([1, 3, 4]))
  })

  it("restores unrestricted selection after removing the last individual provider", async () => {
    const user = userEvent.setup()
    const onApply = vi.fn()
    render(
      <ProviderFilterSheet
        providers={providers}
        selectedProviders={new Set([1, 2])}
        onApply={onApply}
      />,
    )
    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("TuViandita"))
    expect(screen.getByLabelText("Todos")).not.toBeChecked()
    await user.click(screen.getByLabelText("Chef Express"))
    screen
      .getAllByRole("checkbox")
      .forEach((checkbox) => expect(checkbox).toBeChecked())
    await user.click(screen.getByRole("button", { name: "Aplicar" }))
    expect(onApply).toHaveBeenLastCalledWith(new Set())
  })

  it("discards general selection on cancel and restores the applied subset on reopen", async () => {
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
    screen
      .getAllByRole("checkbox")
      .forEach((checkbox) => expect(checkbox).toBeChecked())
    await user.click(screen.getByRole("button", { name: "Cancelar" }))
    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    expect(screen.getByLabelText("TuViandita")).toBeChecked()
    expect(screen.getByLabelText("Chef Express")).not.toBeChecked()
    expect(screen.getByLabelText("Todos")).not.toBeChecked()
    expect(onApply).not.toHaveBeenCalled()
  })

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
    const icon = screen
      .getByRole("button", { name: "Filtrar por proveedores" })
      .querySelector("svg")
    expect(icon).toHaveClass("lucide-settings-2")
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

    await user.click(screen.getByLabelText("Chef Express"))
    await user.click(screen.getByLabelText("La Cocina"))
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

  it("allows selecting only one provider in single selection mode", async () => {
    const user = userEvent.setup()
    const onApply = vi.fn()

    render(
      <ProviderFilterSheet
        providers={providers}
        selectedProviders={new Set<number>()}
        onApply={onApply}
        selectionMode="single"
        allProvidersLabel="Todos los proveedores"
      />,
    )

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("TuViandita"))
    await user.click(screen.getByLabelText("Chef Express"))
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expect(onApply).toHaveBeenCalledWith(new Set([2]))
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

  it("deselects the active provider in single mode and keeps the custom all label", async () => {
    const user = userEvent.setup()
    const onApply = vi.fn()

    render(
      <ProviderFilterSheet
        providers={providers}
        selectedProviders={new Set([1])}
        selectionMode="single"
        allProvidersLabel="Todos los proveedores"
        onApply={onApply}
      />,
    )

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    expect(
      screen.getByRole("heading", { name: "Filtrar por proveedores" }),
    ).toBeInTheDocument()
    expect(screen.getByLabelText("TuViandita")).toBeChecked()
    await user.click(screen.getByLabelText("TuViandita"))
    expect(screen.getByLabelText("Todos los proveedores")).toBeChecked()
    await user.click(screen.getByRole("button", { name: "Aplicar" }))

    expect(onApply).toHaveBeenCalledWith(new Set())
  })

  it("restores the applied provider after cancelling a new draft", async () => {
    const user = userEvent.setup()
    const onApply = vi.fn()

    render(
      <ProviderFilterSheet
        providers={providers}
        selectedProviders={new Set([1])}
        selectionMode="single"
        onApply={onApply}
      />,
    )

    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )
    await user.click(screen.getByLabelText("Chef Express"))
    await user.click(screen.getByRole("button", { name: "Cancelar" }))
    await user.click(
      screen.getByRole("button", { name: "Filtrar por proveedores" }),
    )

    expect(screen.getByLabelText("TuViandita")).toBeChecked()
    expect(screen.getByLabelText("Chef Express")).not.toBeChecked()
    expect(onApply).not.toHaveBeenCalled()
  })
})
