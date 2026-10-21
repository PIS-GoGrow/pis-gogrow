import { act, fireEvent, render, screen } from "@testing-library/react"
import type React from "react"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

import Show from "./show"

const { post } = vi.hoisted(() => ({ post: vi.fn() }))

vi.mock("@inertiajs/react", () => ({
  Head: () => null,
  Link: ({ children }: { children: React.ReactNode }) => <a>{children}</a>,
  Form: ({
    children,
  }: {
    children: (props: {
      processing: boolean
      errors: Record<string, string[]>
    }) => React.ReactNode
  }) => <form>{children({ processing: false, errors: {} })}</form>,
  router: { post },
}))

vi.mock("@/layouts/auth-layout", () => ({
  default: ({
    children,
    description,
  }: {
    children: React.ReactNode
    description: string
  }) => (
    <div>
      <p>{description}</p>
      {children}
    </div>
  ),
}))

function tick(seconds: number) {
  for (let i = 0; i < seconds; i++) {
    act(() => {
      vi.advanceTimersByTime(1000)
    })
  }
}

describe("Provider password reset code page", () => {
  beforeEach(() => {
    vi.useFakeTimers()
    post.mockClear()
  })

  afterEach(() => vi.useRealTimers())

  it("names the email and counts the resend time down from the server value", () => {
    render(<Show email="ana@proveedor.com" resend_in={300} />)

    expect(screen.getByText(/ana@proveedor.com/)).toBeInTheDocument()
    const resend = screen.getByRole("button", {
      name: "Volver a mandar código en 5:00",
    })
    expect(resend).toBeDisabled()

    tick(61)

    expect(
      screen.getByRole("button", { name: "Volver a mandar código en 3:59" }),
    ).toBeDisabled()
  })

  it("enables the resend button when the time is up and asks for a new code", () => {
    render(<Show email="ana@proveedor.com" resend_in={2} />)

    tick(2)

    const resend = screen.getByRole("button", {
      name: "Volver a mandar código",
    })
    expect(resend).toBeEnabled()

    fireEvent.click(resend)
    expect(post).toHaveBeenCalledWith(
      { url: "/proveedor/contrasena", method: "post" },
      { email: "ana@proveedor.com" },
    )
  })

  it("keeps verify disabled until the six digits are typed", () => {
    render(<Show email="ana@proveedor.com" resend_in={0} />)

    const verify = screen.getByRole("button", { name: "Verificar" })
    expect(verify).toBeDisabled()

    const input = document.querySelector("input[name=code]")!
    fireEvent.change(input, { target: { value: "12345" } })
    expect(verify).toBeDisabled()

    fireEvent.change(input, { target: { value: "123456" } })
    expect(verify).toBeEnabled()
  })
})
