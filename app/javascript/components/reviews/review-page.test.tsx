import { act, render } from "@testing-library/react"
import { afterEach, describe, expect, it, vi } from "vitest"

import ReviewPage from "./review-page"

afterEach(() => vi.unstubAllGlobals())

describe("ReviewPage", () => {
  it("adapta el espacio disponible cuando el teclado reduce el viewport", () => {
    const viewport = Object.assign(new EventTarget(), { height: 874 })
    vi.stubGlobal("visualViewport", viewport)
    const { container, unmount } = render(<ReviewPage>Contenido</ReviewPage>)
    const page = container.firstElementChild as HTMLElement
    expect(page.style.getPropertyValue("--review-viewport-height")).toBe(
      "874px",
    )

    act(() => {
      viewport.height = 480
      viewport.dispatchEvent(new Event("resize"))
    })
    expect(page.style.getPropertyValue("--review-viewport-height")).toBe(
      "480px",
    )
    unmount()
  })
})
