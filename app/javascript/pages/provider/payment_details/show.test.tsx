import { render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import PaymentDetails from "./show"

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    Link: ({
      children,
      href,
    }: {
      children: React.ReactNode
      href: string | { url: string }
    }) => <a href={typeof href === "string" ? href : href.url}>{children}</a>,
    Form: ({
      children,
      className,
    }: {
      children: (props: {
        errors: Record<string, string>
        processing: boolean
      }) => React.ReactNode
      className?: string
    }) => (
      <form className={className}>
        {children({ errors: {}, processing: false })}
      </form>
    ),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}))

vi.mock("@/components/page-container", () => ({
  default: ({ children }: { children: React.ReactNode }) => <>{children}</>,
}))

const provider = {
  bank_name: "Santander",
  bank_account_details:
    "Transferencias dentro de Santander\nCuenta: 1150260\nMoneda: UYU\nSucursal: 70 - Golf\n\nTransferencias desde otros bancos\nCuenta: 0070000001150260\nMoneda: UYU",
  beneficiary: "Tu Viandita S.A.",
}

describe("Provider payment details", () => {
  it("muestra los datos completos como texto de consulta", () => {
    render(
      <PaymentDetails
        provider={provider}
        bank_names={["BROU", "Santander"]}
        editing={false}
      />,
    )

    expect(
      screen.getByRole("heading", {
        name: "Transferencias dentro de Santander",
      }),
    ).toBeInTheDocument()
    expect(
      screen.getByRole("heading", {
        name: "Transferencias desde otros bancos",
      }),
    ).toBeInTheDocument()
    expect(screen.getByText("Nº de cuenta: 1150260")).toBeInTheDocument()
    expect(
      screen.getByText("Nº de cuenta: 0070000001150260"),
    ).toBeInTheDocument()
    expect(screen.getByText("Sucursal: 70 - Golf")).toBeInTheDocument()
    expect(screen.getAllByText("Beneficiario: Tu Viandita S.A.")).toHaveLength(
      2,
    )
    expect(screen.queryByText(/Moneda:/)).not.toBeInTheDocument()
    expect(screen.getByRole("link", { name: "Editar" })).toHaveAttribute(
      "href",
      "/proveedor/datos-de-cobro?edit=true",
    )
    expect(screen.queryByRole("textbox")).not.toBeInTheDocument()
  })

  it("muestra el número guardado cuando los datos tienen un solo bloque", () => {
    render(
      <PaymentDetails
        provider={{
          ...provider,
          bank_name: "BROU",
          bank_account_details: "Cuenta: 001234567-00001\nMoneda: UYU",
        }}
        bank_names={["BROU", "Santander"]}
        editing={false}
      />,
    )

    expect(
      screen.getByText("Nº de cuenta: 001234567-00001"),
    ).toBeInTheDocument()
    expect(screen.queryByText("Moneda: UYU")).not.toBeInTheDocument()
  })

  it("muestra sólo los tres campos de Figma al editar", () => {
    render(
      <PaymentDetails
        provider={provider}
        bank_names={["BROU", "Santander"]}
        editing
      />,
    )

    expect(screen.getByLabelText("Banco")).toHaveTextContent("Santander")
    expect(screen.getByLabelText("Datos de la cuenta")).toHaveValue(
      provider.bank_account_details,
    )
    expect(screen.getByLabelText("Beneficiario")).toHaveValue(
      provider.beneficiary,
    )
    expect(screen.queryByLabelText("Tipo de cuenta")).not.toBeInTheDocument()
    expect(
      screen.queryByLabelText("RUT o CI del titular"),
    ).not.toBeInTheDocument()
    expect(screen.getByRole("link", { name: "Cancelar" })).toBeInTheDocument()
  })
})
