import { Link } from "@inertiajs/react"

import ProviderOrderActions from "@/components/orders/provider-order-actions"
import ProviderOrderCardSummary, {
  providerOrderCustomer,
} from "@/components/orders/provider-order-card-summary"
import type { ProviderOrderDecision } from "@/components/orders/provider-order-decided-sheet"
import { providerOrders } from "@/routes"
import type { ProviderOrder } from "@/types"

interface ProviderOrderCardProps {
  order: ProviderOrder
  onDecided: (decision: ProviderOrderDecision) => void
}

export default function ProviderOrderCard({
  order,
  onDecided,
}: ProviderOrderCardProps) {
  return (
    <ProviderOrderCardSummary
      order={order}
      title={
        <Link
          href={providerOrders.show(order.id).url}
          className="after:absolute after:inset-0 hover:underline"
        >
          {providerOrderCustomer(order)}
        </Link>
      }
      footer={
        <ProviderOrderActions
          order={order}
          onDecided={onDecided}
          className="relative w-full"
        />
      }
    />
  )
}
