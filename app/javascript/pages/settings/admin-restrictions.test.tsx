import { render, waitFor } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

import Email from "./emails/show"
import Password from "./passwords/show"

const { visitMock } = vi.hoisted(() => ({ visitMock: vi.fn() }))

vi.mock("@inertiajs/react", async () => {
  const actual = await vi.importActual("@inertiajs/react")
  return {
    ...actual,
    router: { visit: visitMock },
    usePage: () => ({
      props: {
        auth: {
          user: { email: "rrhh@example.com", verified: true },
          session: { role: "admin" },
        },
      },
    }),
  }
})

describe("RRHH restricted settings", () => {
  beforeEach(() => visitMock.mockClear())

  it.each([
    ["email", () => <Email />],
    ["password", () => <Password />],
  ])(
    "redirects direct %s access without rendering its form",
    async (_, page) => {
      const { container } = render(page())

      expect(container).toBeEmptyDOMElement()
      await waitFor(() =>
        expect(visitMock).toHaveBeenCalledWith("/admin/preferencias", {
          replace: true,
        }),
      )
    },
  )
})
