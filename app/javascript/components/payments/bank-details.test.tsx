import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { toast } from "sonner"
import { describe, expect, it, vi } from "vitest"

import BankDetails from "./bank-details"

vi.mock("sonner", () => ({ toast: { success: vi.fn(), error: vi.fn() } }))

const provider = {
  id: 1,
  name: "Endulzate by Noe",
  home_delivery: false,
  bank_name: "Banco Itaú",
  bank_account_details: "Cuenta: 1951234\nMoneda: UYU",
  beneficiary: "Noelia Patricia Pinheiro",
  payment_details_complete: true,
}

describe("BankDetails", () => {
  it("muestra la cuenta como en el diseño", () => {
    render(<BankDetails provider={provider} />)

    expect(screen.getByText("Banco Itaú")).toBeInTheDocument()
    expect(screen.getByText(/Cuenta: 1951234/)).toBeInTheDocument()
    expect(
      screen.getByText("Beneficiario: Noelia Patricia Pinheiro"),
    ).toBeInTheDocument()
  })

  it("copia los datos de la cuenta y avisa", async () => {
    const user = userEvent.setup()
    render(<BankDetails provider={provider} />)

    await user.click(
      screen.getByRole("button", { name: "Copiar datos de la cuenta" }),
    )

    expect(await navigator.clipboard.readText()).toBe(
      "Cuenta: 1951234\nMoneda: UYU",
    )
    expect(toast.success).toHaveBeenCalledWith("Datos de la cuenta copiados")
  })

  it("avisa si el proveedor todavía no cargó sus datos", () => {
    render(
      <BankDetails
        provider={{
          ...provider,
          bank_name: null,
          bank_account_details: null,
          beneficiary: null,
          payment_details_complete: false,
        }}
      />,
    )

    expect(
      screen.getByText("Este proveedor todavía no cargó sus datos de cobro."),
    ).toBeInTheDocument()
    expect(screen.queryByRole("button")).not.toBeInTheDocument()
  })
})
