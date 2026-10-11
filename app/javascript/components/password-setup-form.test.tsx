import { fireEvent, render, screen } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

import PasswordSetupForm from "./password-setup-form"

vi.mock("@inertiajs/react", () => ({
  Form: ({
    children,
  }: {
    children: (props: {
      processing: boolean
      errors: Record<string, string[]>
    }) => React.ReactNode
  }) => <form>{children({ processing: false, errors: {} })}</form>,
}))

const action = { url: "/proveedores/invitacion", method: "patch" as const }
const strong = "Nueva-Clave-2026-ok!"

function setup(props: { email?: string } = {}) {
  render(
    <PasswordSetupForm action={action} submitLabel="Registrarse" {...props} />,
  )
  const password = document.getElementById("password") as HTMLInputElement
  const confirmation = document.getElementById(
    "password_confirmation",
  ) as HTMLInputElement
  const submit = screen.getByRole("button", { name: "Registrarse" })
  const type = (input: HTMLInputElement, value: string) =>
    fireEvent.change(input, { target: { value } })
  return { password, confirmation, submit, type }
}

describe("PasswordSetupForm", () => {
  it("keeps the button disabled until the password is strong and confirmed", () => {
    const { password, confirmation, submit, type } = setup()
    expect(submit).toBeDisabled()

    type(password, strong)
    expect(submit).toBeDisabled()

    type(confirmation, strong)
    expect(submit).toBeEnabled()
  })

  it("keeps the button disabled when the confirmation does not match and says so", () => {
    const { password, confirmation, submit, type } = setup()

    type(password, strong)
    type(confirmation, "otra")

    expect(submit).toBeDisabled()
    expect(screen.getByText(/no coincide/i)).toBeInTheDocument()
  })

  it("keeps the button disabled for a weak password even if it matches", () => {
    const { password, confirmation, submit, type } = setup()

    type(password, "corta")
    type(confirmation, "corta")

    expect(submit).toBeDisabled()
  })

  it("marks each requirement as it is met", () => {
    const { password, type } = setup()
    const met = () =>
      screen
        .getAllByRole("listitem")
        .filter((item) => item.dataset.met === "true").length

    expect(met()).toBe(0)
    type(password, "A")
    expect(met()).toBe(1)
    type(password, "Aa1!aaaaaaaaaaaa")
    expect(met()).toBe(4)
  })

  it("shows the email read-only only when it is given", () => {
    setup({ email: "ana@proveedor.com" })

    const email = document.getElementById("email") as HTMLInputElement
    expect(email.value).toBe("ana@proveedor.com")
    expect(email).toHaveAttribute("readonly")
  })
})
