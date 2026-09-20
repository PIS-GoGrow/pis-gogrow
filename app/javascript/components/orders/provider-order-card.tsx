import { Link } from "@inertiajs/react"
import { MapPin } from "lucide-react"
import { useTranslation } from "react-i18next"

import ListItemCard from "@/components/list-item-card"
import StatusBadge from "@/components/status-badge"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Button } from "@/components/ui/button"
import {
  CardAction,
  CardContent,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { useFormatters } from "@/hooks/use-formatters"
import { useInitials } from "@/hooks/use-initials"
import { providerOrders } from "@/routes"
import type { ProviderOrder } from "@/types"

interface ProviderOrderCardProps {
  order: ProviderOrder
}

export default function ProviderOrderCard({ order }: ProviderOrderCardProps) {
  const { t } = useTranslation()
  const getInitials = useInitials()
  const { formatMoney } = useFormatters()

  return (
    <ListItemCard className="relative">
      <CardHeader>
        <div className="flex items-center gap-3">
          <Avatar size="lg">
            <AvatarFallback className="text-foreground text-xs font-semibold">
              {getInitials(order.consumer_name)}
            </AvatarFallback>
          </Avatar>
          <div className="grid gap-1">
            <CardTitle>
              <Link
                href={providerOrders.show(order.id).url}
                className="after:absolute after:inset-0 hover:underline"
              >
                {order.consumer_name}
              </Link>
            </CardTitle>
            <CardDescription className="text-xs">
              {t("pages.provider_orders.index.code", { id: order.id })} ·{" "}
              {order.time}
            </CardDescription>
          </div>
        </div>
        <CardAction>
          <StatusBadge status={order.status} />
        </CardAction>
      </CardHeader>

      <CardContent className="grid gap-3">
        <div className="grid gap-1">
          <p>
            {order.menu_name}{" "}
            <span className="text-muted-foreground font-normal">
              {t("pages.provider_orders.index.quantity", {
                count: order.amount ?? 0,
              })}
            </span>
          </p>
          {order.notes && (
            <p className="text-muted-foreground text-sm">{order.notes}</p>
          )}
        </div>
        <div className="flex items-end justify-between gap-4">
          <p className="text-muted-foreground flex items-center gap-1.5 text-xs">
            <MapPin className="size-3.5 shrink-0" aria-hidden="true" />
            {order.address ?? t("pages.provider_orders.index.no_address")}
          </p>
          <p className="text-lg font-semibold">{formatMoney(order.price)}</p>
        </div>
      </CardContent>

      {order.status === "pending" && (
        <CardFooter className="flex-col gap-4">
          <Separator />
          <div className="relative grid w-full grid-cols-2 gap-2">
            <Button type="button" variant="outline" size="lg">
              {t("pages.provider_orders.index.cancel")}
            </Button>
            <Button type="button" size="lg">
              {t("pages.provider_orders.index.confirm")}
            </Button>
          </div>
        </CardFooter>
      )}
    </ListItemCard>
  )
}
