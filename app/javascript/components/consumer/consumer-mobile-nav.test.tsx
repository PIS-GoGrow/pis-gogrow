import { render, screen } from "@testing-library/react"
import type React from "react"
import { describe, expect, it, vi } from "vitest"

import { settingsNotifications } from "@/routes"

import { ConsumerMobileNav } from "./consumer-mobile-nav"

const mocks = vi.hoisted(() => ({
  url: "",
}))

vi.mock("@inertiajs/react", () => ({
  Link: ({
    href,
    children,
    className,
    "aria-current": ariaCurrent,
  }: {
    href: string
    children: React.ReactNode
    className?: string
    "aria-current"?: React.AriaAttributes["aria-current"]
  }) => (
    <a href={href} className={className} aria-current={ariaCurrent}>
      {children}
    </a>
  ),
  usePage: () => ({ url: mocks.url }),
}))

describe("ConsumerMobileNav", () => {
  it("keeps Cuenta active while the consumer is in notification settings", () => {
    mocks.url = settingsNotifications.index().url

    render(<ConsumerMobileNav />)

    expect(screen.getByRole("link", { name: "Cuenta" })).toHaveAttribute(
      "aria-current",
      "page",
    )
  })
})
