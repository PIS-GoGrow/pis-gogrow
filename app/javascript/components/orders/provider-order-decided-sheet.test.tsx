import { fireEvent, render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { useState } from "react"
import { expect, it } from "vitest"

import ProviderOrderDecidedSheet, {
  type ProviderOrderDecision,
} from "./provider-order-decided-sheet"

const decision: ProviderOrderDecision = {
  id: 42,
  consumer_name: "Santiago Medina",
  status: "confirmed",
}

function TestSheet() {
  const [current, setCurrent] = useState<ProviderOrderDecision | null>(decision)

  return (
    <ProviderOrderDecidedSheet
      decision={current}
      onClose={() => setCurrent(null)}
    />
  )
}

it("solo se cierra al pulsar Listo", async () => {
  const user = userEvent.setup()
  render(<TestSheet />)

  await user.keyboard("{Escape}")
  expect(screen.getByRole("dialog")).toBeInTheDocument()

  const overlay = document.querySelector('[data-slot="dialog-overlay"]')
  expect(overlay).not.toBeNull()
  fireEvent.pointerDown(overlay!)
  fireEvent.pointerUp(overlay!)
  fireEvent.click(overlay!)
  expect(screen.getByRole("dialog")).toBeInTheDocument()

  await user.click(screen.getByRole("button", { name: "Listo" }))
  expect(screen.queryByRole("dialog")).not.toBeInTheDocument()
})
