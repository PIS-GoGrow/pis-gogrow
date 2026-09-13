import { MapPin } from "lucide-react"

import ListItemCard from "@/components/list-item-card"
import OrderStatusBadge from "@/components/orders/order-status-badge"
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
import { useInitials } from "@/hooks/use-initials"
import { formatPrice } from "@/lib/utils"
import type { ProviderOrder } from "@/types"

interface OrderCardProps {
  order: ProviderOrder
}

export default function OrderCard({ order }: OrderCardProps) {
  const getInitials = useInitials()
  const hasActions = order.status === "pending" || order.status === "confirmed"

  return (
    <ListItemCard>
      <CardHeader>
        <div className="flex items-center gap-3">
          <Avatar size="lg">
            <AvatarFallback className="text-foreground text-xs font-semibold">
              {getInitials(order.consumer_name)}
            </AvatarFallback>
          </Avatar>
          <div className="grid gap-1">
            <CardTitle>{order.consumer_name}</CardTitle>
            <CardDescription className="text-xs">
              PED-{order.id} · {order.time}
            </CardDescription>
          </div>
        </div>
        <CardAction>
          <OrderStatusBadge status={order.status} />
        </CardAction>
      </CardHeader>

      <CardContent className="grid gap-3">
        <div className="grid gap-1">
          <p>
            {(order.amount ?? 1) > 1 && `${order.amount} × `}
            {order.menu_name}
          </p>
          {order.notes && (
            <p className="text-muted-foreground text-sm">{order.notes}</p>
          )}
        </div>
        <div className="flex items-end justify-between gap-4">
          {order.address ? (
            <p className="text-muted-foreground flex items-center gap-1.5 text-xs">
              <MapPin className="size-3.5 shrink-0" aria-hidden="true" />
              {order.address}
            </p>
          ) : (
            <span />
          )}
          <p className="text-lg font-semibold">{formatPrice(order.price)}</p>
        </div>
      </CardContent>

      {hasActions && (
        <CardFooter className="flex-col gap-4">
          <Separator />
          {order.status === "pending" ? (
            <div className="grid w-full grid-cols-2 gap-2">
              <Button type="button" variant="outline" size="lg">
                Cancelar
              </Button>
              <Button type="button" size="lg">
                Confirmar
              </Button>
            </div>
          ) : (
            <Button type="button" size="lg" className="w-full">
              Marcar como entregado
            </Button>
          )}
        </CardFooter>
      )}
    </ListItemCard>
  )
}
