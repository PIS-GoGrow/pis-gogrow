import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import type React from "react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import Profile from "./show"

const patchMock = vi.fn()

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    Head: () => null,
    usePage: () => ({
      props: {
        auth: {
          user: { name: "Proveedor Test" },
        },
      },
    }),
    router: {
      patch: (...args: unknown[]) => {
        patchMock(...args)
      },
    },
    Form: ({
      children,
    }: {
      children: (props: {
        errors: Record<string, string[]>
        processing: boolean
        recentlySuccessful: boolean
      }) => React.ReactNode
    }) => (
      <form>
        {children({
          errors: {},
          processing: false,
          recentlySuccessful: false,
        })}
      </form>
    ),
  }
})

vi.mock("@/layouts/app-layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="app-layout">{children}</div>
  ),
}))

vi.mock("@/layouts/settings/layout", () => ({
  default: ({ children }: { children: React.ReactNode }) => (
    <div data-testid="settings-layout">{children}</div>
  ),
}))

vi.mock("@/components/delete-user", () => ({
  default: () => <div data-testid="delete-user" />,
}))

describe("Settings Profiles Show Page", () => {
  const user = userEvent.setup()

  beforeEach(() => {
    patchMock.mockClear()
  })

  it("does not render home delivery settings when provider is null (consumer/admin)", () => {
    render(<Profile provider={null} />)

    expect(
      screen.queryByText("Editar información de pedidos"),
    ).not.toBeInTheDocument()
    expect(
      screen.queryByLabelText("También realizo entregas a domicilio"),
    ).not.toBeInTheDocument()
  })

  it("renders home delivery switch checked when provider.home_delivery is true", () => {
    render(
      <Profile
        provider={{
          id: 1,
          name: "Proveedor Test",
          home_delivery: true,
        }}
      />,
    )

    expect(
      screen.getByText("Editar información de pedidos"),
    ).toBeInTheDocument()
    const switchControl = screen.getByRole("switch", {
      name: "También realizo entregas a domicilio",
    })
    expect(switchControl).toBeInTheDocument()
    expect(switchControl).toHaveAttribute("aria-checked", "true")
  })

  it("renders home delivery switch unchecked when provider.home_delivery is false", () => {
    render(
      <Profile
        provider={{
          id: 1,
          name: "Proveedor Test",
          home_delivery: false,
        }}
      />,
    )

    const switchControl = screen.getByRole("switch", {
      name: "También realizo entregas a domicilio",
    })
    expect(switchControl).toBeInTheDocument()
    expect(switchControl).toHaveAttribute("aria-checked", "false")
  })

  it("calls router.patch with home_delivery: false when clicked while checked", async () => {
    render(
      <Profile
        provider={{
          id: 1,
          name: "Proveedor Test",
          home_delivery: true,
        }}
      />,
    )

    const switchControl = screen.getByRole("switch", {
      name: "También realizo entregas a domicilio",
    })
    await user.click(switchControl)

    expect(patchMock).toHaveBeenCalledTimes(1)
    expect(patchMock).toHaveBeenCalledWith(
      expect.anything(),
      { home_delivery: false },
      expect.objectContaining({
        preserveScroll: true,
      }),
    )
  })

  it("calls router.patch with home_delivery: true when clicked while unchecked", async () => {
    render(
      <Profile
        provider={{
          id: 1,
          name: "Proveedor Test",
          home_delivery: false,
        }}
      />,
    )

    const switchControl = screen.getByRole("switch", {
      name: "También realizo entregas a domicilio",
    })
    await user.click(switchControl)

    expect(patchMock).toHaveBeenCalledTimes(1)
    expect(patchMock).toHaveBeenCalledWith(
      expect.anything(),
      { home_delivery: true },
      expect.objectContaining({
        preserveScroll: true,
      }),
    )
  })
})
