import { usePage } from "@inertiajs/react"
import type { ReactNode } from "react"

import { Toaster } from "@/components/ui/sonner"
import { ConsumerMenuFilterProvider } from "@/hooks/consumer-menu-filter"
import { useConsumerCartCleanup } from "@/hooks/use-consumer-cart"
import { useFlash } from "@/hooks/use-flash"
import { useLocale } from "@/hooks/use-locale"
import { useNetworkStatus } from "@/hooks/use-network-status"
import { useSentryContext } from "@/hooks/use-sentry-context"

interface PersistentLayoutProps {
  children: ReactNode
}

export default function PersistentLayout({ children }: PersistentLayoutProps) {
  const { auth } = usePage().props
  const sessionKey = auth?.session
    ? `${auth.session.id}:${auth.session.role}`
    : "guest"
  useFlash()
  useLocale()
  useNetworkStatus()
  useSentryContext()
  useConsumerCartCleanup()
  return (
    <>
      <ConsumerMenuFilterProvider key={sessionKey}>
        {children}
      </ConsumerMenuFilterProvider>
      <Toaster richColors />
    </>
  )
}
