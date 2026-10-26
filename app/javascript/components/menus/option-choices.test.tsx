import "@testing-library/jest-dom/vitest"

import { cleanup, render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, describe, expect, it, vi } from "vitest"

import OptionChoices, { type OptionGroup } from "./option-choices"

afterEach(cleanup)

describe("OptionChoices", () => {
  const singleChoiceGroup: OptionGroup = {
    id: 1,
    name: "Salsa",
    options: ["Filetto", "Bolognesa"],
    limit: 1,
    required: true,
  }

  const multiChoiceGroup: OptionGroup = {
    id: 2,
    name: "Extras",
    options: ["Papas", "Ensalada", "Huevo"],
    limit: 2,
    required: false,
  }

  it("shows group name and 'Obligatorio' indicator when required", () => {
    render(
      <OptionChoices
        group={singleChoiceGroup}
        values={[]}
        setValues={vi.fn()}
      />,
    )

    expect(screen.getByText("Elegí tu/s salsa/s")).toBeInTheDocument()
    expect(screen.getByText("Obligatorio")).toBeInTheDocument()
  })

  it("shows 'Opcional' indicator when group is not required", () => {
    render(
      <OptionChoices
        group={multiChoiceGroup}
        values={[]}
        setValues={vi.fn()}
      />,
    )

    expect(screen.getByText("Elegí tu/s extras")).toBeInTheDocument()
    expect(screen.getByText("Opcional")).toBeInTheDocument()
  })

  it("writes a name ending in a consonant with '/es'", () => {
    render(
      <OptionChoices
        group={{ ...singleChoiceGroup, name: "Guarnición" }}
        values={[]}
        setValues={vi.fn()}
      />,
    )

    expect(screen.getByText("Elegí tu/s guarnición/es")).toBeInTheDocument()
  })

  it("selects an option in a single-choice group", async () => {
    const user = userEvent.setup()
    const setValues = vi.fn()

    render(
      <OptionChoices
        group={singleChoiceGroup}
        values={[]}
        setValues={setValues}
      />,
    )

    await user.click(screen.getByRole("radio", { name: "Filetto" }))
    expect(setValues).toHaveBeenCalledWith(["Filetto"])
  })

  it("unselects the chosen option when clicked again in a single-choice group", async () => {
    const user = userEvent.setup()
    const setValues = vi.fn()

    render(
      <OptionChoices
        group={singleChoiceGroup}
        values={["Filetto"]}
        setValues={setValues}
      />,
    )

    await user.click(screen.getByRole("radio", { name: "Filetto" }))
    expect(setValues).toHaveBeenCalledWith([])
  })

  it("manages multi-choice selection and disables unselected options at limit", () => {
    const setValues = vi.fn()

    const { rerender } = render(
      <OptionChoices
        group={multiChoiceGroup}
        values={["Papas"]}
        setValues={setValues}
      />,
    )

    expect(screen.getByRole("checkbox", { name: "Papas" })).toBeChecked()
    expect(
      screen.getByRole("checkbox", { name: "Ensalada" }),
    ).not.toBeDisabled()

    // At limit
    rerender(
      <OptionChoices
        group={multiChoiceGroup}
        values={["Papas", "Ensalada"]}
        setValues={setValues}
      />,
    )

    expect(screen.getByRole("checkbox", { name: "Huevo" })).toBeDisabled()
    expect(screen.getByRole("checkbox", { name: "Papas" })).not.toBeDisabled()
  })
})
