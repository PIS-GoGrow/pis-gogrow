import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import { QuantityInput } from "./quantity-input"

describe("QuantityInput", () => {
  it("disables the minus at the minimum when there is no onRemove", () => {
    render(<QuantityInput value={1} max={5} onChange={vi.fn()} />)

    expect(screen.getByRole("button", { name: "Quitar uno" })).toBeDisabled()
  })

  it("keeps the minus at the minimum for the other counters", async () => {
    const onChange = vi.fn()
    render(<QuantityInput value={3} max={5} onChange={onChange} />)

    await userEvent.click(screen.getByRole("button", { name: "Quitar uno" }))

    expect(onChange).toHaveBeenCalledWith(2)
  })

  it("shows a trash that calls onRemove when it reaches the minimum", async () => {
    const onChange = vi.fn()
    const onRemove = vi.fn()
    render(
      <QuantityInput
        value={1}
        max={5}
        onChange={onChange}
        onRemove={onRemove}
      />,
    )

    await userEvent.click(screen.getByRole("button", { name: "Quitar" }))

    expect(onRemove).toHaveBeenCalledTimes(1)
    expect(onChange).not.toHaveBeenCalled()
  })

  it("shows the minus while the quantity is above the minimum", async () => {
    const onChange = vi.fn()
    const onRemove = vi.fn()
    render(
      <QuantityInput
        value={2}
        max={5}
        onChange={onChange}
        onRemove={onRemove}
      />,
    )

    await userEvent.click(screen.getByRole("button", { name: "Quitar uno" }))

    expect(onChange).toHaveBeenCalledWith(1)
    expect(onRemove).not.toHaveBeenCalled()
  })
})
