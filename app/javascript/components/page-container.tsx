import type { ReactNode } from "react"

import Heading from "@/components/heading"

interface PageContainerProps {
  title: string
  eyebrow?: string
  description?: string
  badge?: ReactNode
  actions?: ReactNode
  back?: ReactNode
  titleVariant?: "default" | "prominent"
  compactHeading?: boolean
  centered?: boolean
  children: ReactNode
}

export default function PageContainer({
  title,
  eyebrow,
  description,
  badge,
  actions,
  back,
  titleVariant,
  compactHeading,
  centered,
  children,
}: PageContainerProps) {
  return (
    <div className="mx-auto w-full max-w-300 p-5">
      <Heading
        title={title}
        eyebrow={eyebrow}
        description={description}
        badge={badge}
        actions={actions}
        back={back}
        titleVariant={titleVariant}
        compact={compactHeading}
        centered={centered}
      />
      <div className="flex flex-col gap-4">{children}</div>
    </div>
  )
}
