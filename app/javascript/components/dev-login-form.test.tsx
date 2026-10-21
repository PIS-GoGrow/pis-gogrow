import { render, screen } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

import DevLoginForm from "./dev-login-form"

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

vi.mock("@/routes", () => ({
  sessions: {
    create: () => ({ url: "/iniciar-sesion", method: "post" }),
  },
}))

describe("DevLoginForm Component", () => {
  it("renders email and password inputs with submit button", () => {
    render(<DevLoginForm />)

    expect(screen.getByLabelText("Correo electrónico")).toBeInTheDocument()
    expect(screen.getByLabelText("Contraseña")).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Ingresar" })).toBeInTheDocument()
  })
})
