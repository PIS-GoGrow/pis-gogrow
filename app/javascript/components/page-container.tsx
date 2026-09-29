import type { ReactNode } from "react"

import Heading from "@/components/heading"

interface PageContainerProps {
  title: string
  eyebrow?: string
  description?: string
  actions?: ReactNode
  back?: ReactNode
  titleVariant?: "default" | "prominent"
  children: ReactNode
}

export default function PageContainer({
  title,
  eyebrow,
  description,
  actions,
  back,
  titleVariant,
  children,
}: PageContainerProps) {
  return (
    <div className="mx-auto w-full max-w-300 p-5">
      <Heading
        title={title}
        eyebrow={eyebrow}
        description={description}
        actions={actions}
        back={back}
        titleVariant={titleVariant}
      />
      <div className="flex flex-col gap-4">{children}</div>
    </div>
  )
}
