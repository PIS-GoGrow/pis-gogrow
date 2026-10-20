import { fireEvent, render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import type { AdminConsumerRow } from "@/types"

import Index from "./index"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    usePage: () => ({ url: "/admin/empleados", props: { locale: "es" } }),
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
  {
    id: 3,
    name: "Carla Review",
    email: "carla@gogrow.com",
    avatar_url: null,
    amount: 150,
    status: "submitted",
  },
  {
    id: 4,
    name: "Diego Idle",
    email: "diego@gogrow.com",
    avatar_url: null,
    amount: 0,
    status: null,
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

  it("has only the two tabs of the design", () => {
    render(<Index consumers={consumers} filter="all" />)

    expect(screen.getAllByRole("radio").map((tab) => tab.textContent)).toEqual([
      "Todos",
      "Pendientes",
    ])
  })

  it("lists the pending and under review employees in Pendientes", () => {
    render(<Index consumers={consumers} filter="pending" />)

    expect(screen.getByText("Bruno Owes")).toBeInTheDocument()
    expect(screen.getByText("Carla Review")).toBeInTheDocument()
    expect(screen.queryByText("Diego Idle")).not.toBeInTheDocument()
  })

  it("counts the employees of the tab next to the title, without the search", () => {
    render(<Index consumers={consumers} filter="all" />)

    const heading = screen.getByRole("heading", { name: "Empleados" })
    const title = heading.parentElement
    expect(title).toHaveTextContent("Empleados44 empleados")

    fireEvent.change(screen.getByRole("searchbox"), {
      target: { value: "Ana" },
    })
    expect(title).toHaveTextContent("Empleados44 empleados")

    fireEvent.click(screen.getByRole("radio", { name: "Pendientes" }))
    expect(title).toHaveTextContent("Empleados22 empleados")
  })
})
