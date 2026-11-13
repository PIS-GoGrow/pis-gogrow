import type { PropsWithChildren } from "react"

export default function ReviewActions({ children }: PropsWithChildren) {
  return (
    <div className="bg-background shrink-0 px-5 pt-4 pb-[max(1.25rem,env(safe-area-inset-bottom))]">
      {children}
    </div>
  )
}
