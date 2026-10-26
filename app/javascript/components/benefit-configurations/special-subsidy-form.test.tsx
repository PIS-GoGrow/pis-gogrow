import { render, screen, within } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

import type { Employee, SpecialSubsidy } from "@/types/serializers"

import SpecialSubsidyForm from "./special-subsidy-form"

const postMock = vi.fn()
const patchMock = vi.fn()
let currentFormErrors: Record<string, unknown> = {}
let transformCallback: ((data: Record<string, unknown>) => unknown) | null =
  null

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  const { useState } = await vi.importActual<typeof React>("react")

  return {
    ...actual,
    useForm: (initialValues: Record<string, unknown>) => {
      const [data, setFormData] = useState(initialValues)

      return {
        data,
        setData: (key: string, value: unknown) =>
          setFormData((current) => ({ ...current, [key]: value })),
        post: (...args: unknown[]) => {
          postMock(...args)
        },
        patch: (...args: unknown[]) => {
          patchMock(...args)
        },
        processing: false,
        errors: currentFormErrors,
        transform: (fn: (data: Record<string, unknown>) => unknown) => {
          transformCallback = fn
        },
      }
    },
  }
})

const employees: Employee[] = [
  { id: 1, name: "Matías Rodríguez", short_name: "Matías R." },
  { id: 2, name: "Lucía Fernández", short_name: "Lucía F." },
]

const gift: SpecialSubsidy = {
  id: 7,
  name: "Desafío de Pasos",
  subsidy_percentage: 25,
  applies_to_all: true,
  consumer_ids: [],
  condition: {
    type: "gift",
    limit: 3,
    effective_from: "2099-01-10",
    validity_amount: 2,
    validity_unit: "weeks",
  },
}

function dayButton(day: number) {
  return within(screen.getByRole("grid")).getByRole("button", {
    name: new RegExp(` ${day} de octubre de 2026`),
  })
}

function renderForm(subsidy?: SpecialSubsidy) {
  return render(
    <SpecialSubsidyForm
      subsidy={subsidy}
      employees={employees}
      onCancel={vi.fn()}
      onSuccess={vi.fn()}
    />,
  )
}

describe("SpecialSubsidyForm", () => {
  beforeEach(() => {
    vi.clearAllMocks()
    currentFormErrors = {}
    transformCallback = null
  })

  it("keeps 'Agregar' disabled until the form is valid", () => {
    renderForm()

    expect(screen.getByRole("button", { name: "Agregar" })).toBeDisabled()
    expect(screen.queryByLabelText(/disponible desde/i)).not.toBeInTheDocument()
  })

  it("shows only the fields of the selected condition", () => {
    renderForm(gift)

    expect(screen.getByLabelText(/disponible desde/i)).toHaveTextContent(
      "Sábado 10 de enero",
    )
    expect(screen.getByLabelText(/cantidad de/i)).toHaveValue(3)
    expect(screen.getByLabelText("Validez")).toHaveValue(2)
    expect(screen.queryByLabelText(/es mayor a/i)).not.toBeInTheDocument()
  })

  it("prefills the form when editing and submits with PATCH", async () => {
    const user = userEvent.setup()
    renderForm(gift)

    expect(screen.getByLabelText(/nombre del subsidio/i)).toHaveValue(
      "Desafío de Pasos",
    )

    await user.click(screen.getByRole("button", { name: "Modificar" }))

    expect(patchMock).toHaveBeenCalledWith(
      "/rrhh/subsidios-especiales/7",
      expect.anything(),
    )

    const payload = transformCallback!({ name: "Desafío de Pasos" })

    expect(payload).toEqual({
      special_subsidy: { name: "Desafío de Pasos" },
    })
  })

  it("disables the submit button when a required field is cleared", async () => {
    const user = userEvent.setup()
    renderForm(gift)

    await user.clear(screen.getByLabelText(/nombre del subsidio/i))

    expect(screen.getByRole("button", { name: "Modificar" })).toBeDisabled()
  })

  describe("effective date calendar", () => {
    beforeEach(() => {
      vi.useFakeTimers({ toFake: ["Date"] })
      vi.setSystemTime(new Date(2026, 9, 23, 12))
    })

    afterEach(() => {
      vi.useRealTimers()
    })

    const upcomingGift: SpecialSubsidy = {
      ...gift,
      condition: { ...gift.condition!, effective_from: "2026-10-25" },
    }

    it("does not allow a past effective date for a gift", async () => {
      const user = userEvent.setup()
      renderForm(upcomingGift)

      await user.click(screen.getByLabelText(/disponible desde/i))

      expect(dayButton(22)).toBeDisabled()
      expect(dayButton(23)).toBeEnabled()
    })

    it("sets the effective date picked in the calendar", async () => {
      const user = userEvent.setup()
      renderForm(upcomingGift)

      await user.click(screen.getByLabelText(/disponible desde/i))
      await user.click(dayButton(28))

      expect(screen.getByLabelText(/disponible desde/i)).toHaveTextContent(
        "Miércoles 28 de octubre",
      )
      expect(screen.getByRole("button", { name: "Modificar" })).toBeEnabled()
    })
  })

  it("requires at least one employee when selecting employees", async () => {
    const user = userEvent.setup()
    renderForm(gift)

    await user.click(screen.getByLabelText(/seleccionar empleados/i))

    expect(screen.getByRole("button", { name: "Modificar" })).toBeDisabled()

    await user.type(screen.getByLabelText(/buscar empleado/i), "mati")
    await user.click(screen.getByRole("button", { name: "Matías Rodríguez" }))

    expect(screen.getByText("Matías R.")).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Modificar" })).toBeEnabled()

    await user.click(
      screen.getByRole("button", { name: "Quitar a Matías Rodríguez" }),
    )

    expect(screen.queryByText("Matías R.")).not.toBeInTheDocument()
  })

  it("shows the server errors next to each field", () => {
    currentFormErrors = { name: ["no puede estar en blanco"] }

    renderForm(gift)

    expect(screen.getByText("no puede estar en blanco")).toBeInTheDocument()
  })
})
