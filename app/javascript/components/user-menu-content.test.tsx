import { render, screen } from "@testing-library/react"
import type { ReactNode } from "react"
import { describe, expect, it, vi } from "vitest"

import {
  DropdownMenu,
  DropdownMenuContent,
} from "@/components/ui/dropdown-menu"
import { adminAccount, consumerProfiles, providerAccount } from "@/routes"
import type { User } from "@/types"

import { UserMenuContent } from "./user-menu-content"

const baseUser: User = {
  id: 1,
  name: "Juan Pérez",
  email: "juan@example.com",
  roles: ["consumer"],
  verified: true,
  created_at: "2026-01-01T00:00:00Z",
  updated_at: "2026-01-01T00:00:00Z",
}

vi.mock("@inertiajs/react", async () => ({
  ...(await vi.importActual("@inertiajs/react")),
  Link: ({
    href,
    children,
  }: {
    href: string | { url: string }
    children?: ReactNode
  }) => {
    const url = typeof href === "string" ? href : href.url
    return <a href={url}>{children}</a>
  },
  router: {
    flushAll: vi.fn(),
  },
}))

function renderMenu(role: "consumer" | "provider" | "admin") {
  return render(
    <DropdownMenu open>
      <DropdownMenuContent>
        <UserMenuContent
          auth={{
            session: { id: 1, role },
            user: { ...baseUser, roles: [role] },
          }}
        />
      </DropdownMenuContent>
    </DropdownMenu>,
  )
}

describe("UserMenuContent", () => {
  it("links to consumer account when role is consumer", () => {
    renderMenu("consumer")

    expect(screen.getByRole("link", { name: "Configuración" })).toHaveAttribute(
      "href",
      consumerProfiles.show().url,
    )
  })

  it("links to provider account when role is provider", () => {
    renderMenu("provider")

    expect(screen.getByRole("link", { name: "Configuración" })).toHaveAttribute(
      "href",
      providerAccount().url,
    )
  })

  it("links to admin account when role is admin", () => {
    renderMenu("admin")

    expect(screen.getByRole("link", { name: "Configuración" })).toHaveAttribute(
      "href",
      adminAccount().url,
    )
  })
})
