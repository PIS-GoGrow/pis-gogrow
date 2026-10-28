import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, expect, it, vi } from "vitest"

import { useConsumerMenuFilter } from "@/hooks/consumer-menu-filter"

import PersistentLayout from "./persistent-layout"

const page = vi.hoisted<{
  props: { auth: { session: { id: number; role: string } } | null }
}>(() => ({ props: { auth: { session: { id: 1, role: "consumer" } } } }))
vi.mock("@inertiajs/react", () => ({ usePage: () => page }))
vi.mock("@/hooks/use-flash", () => ({ useFlash: vi.fn() }))
vi.mock("@/hooks/use-locale", () => ({ useLocale: vi.fn() }))
vi.mock("@/hooks/use-sentry-context", () => ({ useSentryContext: vi.fn() }))
vi.mock("@/components/ui/sonner", () => ({ Toaster: () => null }))

function Menu() {
  const { activeProviders, setActiveProviders } = useConsumerMenuFilter()
  return (
    <button onClick={() => setActiveProviders(new Set([1, 2]))}>
      {[...activeProviders].join(",") || "Todos"}
    </button>
  )
}

beforeEach(() => {
  page.props.auth = { session: { id: 1, role: "consumer" } }
})

it("preserves menu state through other pages without sharing the history filter", async () => {
  const user = userEvent.setup()
  const { rerender } = render(
    <PersistentLayout>
      <Menu />
    </PersistentLayout>,
  )
  await user.click(screen.getByRole("button", { name: "Todos" }))
  rerender(
    <PersistentLayout>
      <div>Pagos</div>
    </PersistentLayout>,
  )
  rerender(
    <PersistentLayout>
      <div>Todos los proveedores</div>
    </PersistentLayout>,
  )
  expect(screen.getByText("Todos los proveedores")).toBeInTheDocument()
  rerender(
    <PersistentLayout>
      <Menu />
    </PersistentLayout>,
  )
  expect(screen.getByRole("button", { name: "1,2" })).toBeInTheDocument()
})

it.each(["logout", "new session", "role change"])(
  "clears the menu filter on %s",
  async (change) => {
    const user = userEvent.setup()
    const { rerender } = render(
      <PersistentLayout>
        <Menu />
      </PersistentLayout>,
    )
    await user.click(screen.getByRole("button", { name: "Todos" }))
    page.props.auth =
      change === "logout"
        ? null
        : {
            session: {
              id: change === "new session" ? 2 : 1,
              role: change === "role change" ? "provider" : "consumer",
            },
          }
    rerender(
      <PersistentLayout>
        <Menu />
      </PersistentLayout>,
    )
    expect(screen.getByRole("button", { name: "Todos" })).toBeInTheDocument()
  },
)
