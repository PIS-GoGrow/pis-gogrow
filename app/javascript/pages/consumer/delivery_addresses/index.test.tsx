import { render, screen } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

import type { ConsumerDeliveryAddressesIndex } from "@/types"

import Index from "./index"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")

  return {
    ...actual,
    Head: () => null,
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}))

vi.mock("@/layouts/settings/page-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}))

const props: ConsumerDeliveryAddressesIndex = {
  office_address: "Av. 18 de Julio 1006",
  delivery_addresses: [
    {
      id: 1,
      name: "Casa",
      street: "Ellauri 1234",
      apartment: null,
      address: "Ellauri 1234",
    },
    {
      id: 2,
      name: "Flora Café",
      street: "Canelones 892",
      apartment: "Apto 3",
      address: "Canelones 892, Apto 3",
    },
  ],
}

describe("Consumer delivery addresses index", () => {
  it("lists the office and employee saved addresses", () => {
    render(<Index {...props} />)

    expect(screen.getByText("Oficina")).toBeInTheDocument()
    expect(screen.getByText("Av. 18 de Julio 1006")).toBeInTheDocument()

    expect(screen.getByText("Casa")).toBeInTheDocument()
    expect(screen.getByText("Ellauri 1234")).toBeInTheDocument()

    expect(screen.getByText("Flora Café")).toBeInTheDocument()
    expect(screen.getByText("Canelones 892, Apto 3")).toBeInTheDocument()
  })

  it("does not offer editing for the office address", () => {
    render(<Index {...props} />)

    expect(
      screen.queryByRole("button", { name: "Editar Oficina" }),
    ).not.toBeInTheDocument()

    expect(
      screen.getByRole("button", { name: "Editar Casa" }),
    ).toBeInTheDocument()

    expect(
      screen.getByRole("button", { name: "Editar Flora Café" }),
    ).toBeInTheDocument()
  })

  it("offers adding another address", () => {
    render(<Index {...props} />)

    expect(
      screen.getByRole("button", { name: "Agregar dirección" }),
    ).toBeInTheDocument()
  })

  it("does not render the office card when the company has no address", () => {
    render(<Index {...props} office_address={undefined} />)

    expect(screen.queryByText("Oficina")).not.toBeInTheDocument()
    expect(screen.getByText("Casa")).toBeInTheDocument()
  })
})