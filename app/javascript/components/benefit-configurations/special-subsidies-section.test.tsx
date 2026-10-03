import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import type { SpecialSubsidy } from "@/types/serializers"

import SpecialSubsidiesSection from "./special-subsidies-section"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    useForm: (initialValues: Record<string, unknown>) => ({
      data: initialValues,
      setData: vi.fn(),
      post: vi.fn(),
      patch: vi.fn(),
      processing: false,
      errors: {},
      transform: vi.fn(),
    }),
  }
})

const seniority: SpecialSubsidy = {
  id: 1,
  name: "2 años",
  subsidy_percentage: 25,
  applies_to_all: false,
  consumer_ids: [3],
  condition: { type: "seniority", min_years: 2 },
}

describe("SpecialSubsidiesSection", () => {
  it("renders the empty state", () => {
    render(<SpecialSubsidiesSection specialSubsidies={[]} employees={[]} />)

    expect(screen.getByText("No hay subsidios especiales")).toBeInTheDocument()
    expect(
      screen.getByText("Los subsidios especiales se suman al Base."),
    ).toBeInTheDocument()
  })

  it("renders a card per subsidy with its discount, scope and condition", () => {
    render(
      <SpecialSubsidiesSection specialSubsidies={[seniority]} employees={[]} />,
    )

    expect(screen.getByText("2 años")).toBeInTheDocument()
    expect(screen.getByText("25%")).toBeInTheDocument()
    expect(screen.getByText("Selección")).toBeInTheDocument()
    expect(screen.getByText("Antigüedad")).toBeInTheDocument()
  })

  it("opens the sheet to add a new subsidy", async () => {
    const user = userEvent.setup()
    render(<SpecialSubsidiesSection specialSubsidies={[]} employees={[]} />)

    await user.click(screen.getByRole("button", { name: "Agregar" }))

    const sheet = screen.getByRole("dialog")
    expect(
      within(sheet).getByText("Agregar subsidio especial"),
    ).toBeInTheDocument()
  })

  it("opens the sheet with 'Modificar' to edit a subsidy", async () => {
    const user = userEvent.setup()
    render(
      <SpecialSubsidiesSection specialSubsidies={[seniority]} employees={[]} />,
    )

    await user.click(screen.getByRole("button", { name: "Editar «2 años»" }))

    const sheet = screen.getByRole("dialog")
    expect(within(sheet).getByLabelText(/nombre del subsidio/i)).toHaveValue(
      "2 años",
    )
    expect(
      within(sheet).getByRole("button", { name: "Modificar" }),
    ).toBeInTheDocument()
  })

  it("asks for confirmation before deleting", async () => {
    const user = userEvent.setup()
    render(
      <SpecialSubsidiesSection specialSubsidies={[seniority]} employees={[]} />,
    )

    await user.click(screen.getByRole("button", { name: "Eliminar «2 años»" }))

    expect(screen.getByText("¿Eliminar «2 años»?")).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Eliminar" })).toBeInTheDocument()
  })
})
