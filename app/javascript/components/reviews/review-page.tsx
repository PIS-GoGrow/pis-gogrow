import { useEffect, useRef } from "react"
import type { PropsWithChildren } from "react"

export default function ReviewPage({ children }: PropsWithChildren) {
  const container = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const viewport = window.visualViewport
    const updateHeight = () => {
      container.current?.style.setProperty(
        "--review-viewport-height",
        `${viewport?.height ?? window.innerHeight}px`,
      )
    }

    updateHeight()
    viewport?.addEventListener("resize", updateHeight)
    window.addEventListener("resize", updateHeight)

    return () => {
      viewport?.removeEventListener("resize", updateHeight)
      window.removeEventListener("resize", updateHeight)
    }
  }, [])

  return (
    <div
      ref={container}
      className="mx-auto flex h-[var(--review-viewport-height,100dvh)] min-h-0 w-full max-w-128 flex-col md:h-[calc(var(--review-viewport-height,100dvh)-5rem)]"
    >
      {children}
    </div>
  )
}
