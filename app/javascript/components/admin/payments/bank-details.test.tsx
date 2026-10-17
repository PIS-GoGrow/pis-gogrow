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
  bank_account_number: "1951234",
  bank_account_holder: "Noelia Patricia Pinheiro",
}

describe("BankDetails", () => {
  it("muestra la cuenta como en el diseño", () => {
    render(<BankDetails provider={provider} />)

    expect(screen.getByText("Banco Itaú")).toBeInTheDocument()
    expect(screen.getByText("Nº de cuenta: 1951234")).toBeInTheDocument()
    expect(
      screen.getByText("Beneficiario: Noelia Patricia Pinheiro"),
    ).toBeInTheDocument()
  })

  it("copia el número de cuenta y avisa", async () => {
    const user = userEvent.setup()
    render(<BankDetails provider={provider} />)

    await user.click(
      screen.getByRole("button", { name: "Copiar número de cuenta" }),
    )

    expect(await navigator.clipboard.readText()).toBe("1951234")
    expect(toast.success).toHaveBeenCalledWith("Número de cuenta copiado")
  })

  it("avisa si el proveedor todavía no cargó sus datos", () => {
    render(
      <BankDetails
        provider={{
          ...provider,
          bank_name: null,
          bank_account_number: null,
          bank_account_holder: null,
        }}
      />,
    )

    expect(
      screen.getByText("Este proveedor todavía no cargó sus datos de cobro."),
    ).toBeInTheDocument()
    expect(screen.queryByRole("button")).not.toBeInTheDocument()
  })
})
