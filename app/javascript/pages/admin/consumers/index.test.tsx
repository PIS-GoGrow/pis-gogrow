import { render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import type { AdminConsumerRow } from "@/types"

import Index from "./index"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    usePage: () => ({ url: "/admin/consumers", props: { locale: "es" } }),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

const consumers: AdminConsumerRow[] = [
  {
    id: 1,
    name: "Ana Paid",
    email: "ana@gogrow.com",
    avatar_url: null,
    amount: 150,
    status: "approved",
  },
  {
    id: 2,
    name: "Bruno Owes",
    email: "bruno@gogrow.com",
    avatar_url: null,
    amount: 2425,
    status: "pending",
  },
]

describe("Admin Consumers Page", () => {
  it("opens on the filter the URL asked for", () => {
    render(<Index consumers={consumers} filter="pending" />)

    expect(screen.getByRole("radio", { name: "Pendientes" })).toHaveAttribute(
      "aria-checked",
      "true",
    )
    expect(screen.getByText("Bruno Owes")).toBeInTheDocument()
    expect(screen.queryByText("Ana Paid")).not.toBeInTheDocument()
  })

  it("shows everyone by default", () => {
    render(<Index consumers={consumers} filter="all" />)

    expect(screen.getByText("Ana Paid")).toBeInTheDocument()
    expect(screen.getByText("Bruno Owes")).toBeInTheDocument()
  })
})
