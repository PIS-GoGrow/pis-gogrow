import { Link } from "@inertiajs/react"
import { Pencil, Star, X } from "lucide-react"
import { useTranslation } from "react-i18next"

import CancelOrderSheet from "@/components/orders/cancel-order-sheet"
import { Button } from "@/components/ui/button"
import { CardFooter } from "@/components/ui/card"
import { consumerOrders, consumerReviews } from "@/routes"
import type { Order } from "@/types"

import OrderCardReduced from "./order-card-reduced"

interface OrderCardProps {
  order: Order
  section: "upcoming" | "history"
}

export default function OrderCard({ order, section }: OrderCardProps) {
  const { t } = useTranslation()

  return (
    <OrderCardReduced
      order={order}
      section={section}
      clickable
      title={
        <Link
          href={consumerOrders.show(order.id).url}
          className="after:absolute after:inset-0 hover:underline"
        >
          {order.menu_name ?? t("pages.orders.index.no_menu")}
        </Link>
      }
      footer={
        <>
          {/* El ::after de la tarjeta cubre todo para hacerla clickeable, así que
            las acciones necesitan quedar por encima para poder tocarlas. */}
          {/* El botón se muestra en el historial: habilitado solo si el pedido se
            puede calificar (confirmado, ya entregado y sin reseña). */}
          {section === "history" && (
            <CardFooter className="relative px-4">
              {order.reviewable ? (
                <Button
                  type="button"
                  variant="secondary"
                  size="sm"
                  className="w-full"
                  asChild
                >
                  <Link href={consumerReviews.new(order.id)}>
                    <Star aria-hidden="true" />
                    {t("pages.orders.index.review")}
                  </Link>
                </Button>
              ) : (
                <Button
                  type="button"
                  variant="secondary"
                  size="sm"
                  className="w-full"
                  disabled
                >
                  <Star aria-hidden="true" />
                  {t(
                    order.reviewed
                      ? "pages.orders.index.reviewed"
                      : "pages.orders.index.review",
                  )}
                </Button>
              )}
            </CardFooter>
          )}

          {section === "upcoming" && (
            <CardFooter className="relative grid grid-cols-2 items-start gap-2 px-4">
              {order.cancellable ? (
                <CancelOrderSheet order={order} />
              ) : (
                <div className="flex flex-col gap-1">
                  <Button
                    type="button"
                    variant="secondary"
                    size="sm"
                    className="w-full"
                    disabled
                  >
                    <X aria-hidden="true" />
                    {t("pages.orders.index.cancel")}
                  </Button>
                  {order.status !== "confirmed" && (
                    <p className="text-muted-foreground text-xs">
                      {t(
                        `pages.orders.index.cannot_cancel.${order.cancellation_block_reason}`,
                      )}
                    </p>
                  )}
                </div>
              )}
              {order.modifiable ? (
                <Button
                  type="button"
                  variant="secondary"
                  size="sm"
                  className="w-full"
                  asChild
                >
                  <Link href={consumerOrders.edit(order.id)}>
                    <Pencil aria-hidden="true" />
                    {t("pages.orders.show.edit")}
                  </Link>
                </Button>
              ) : (
                <div className="flex flex-col gap-1">
                  <Button
                    type="button"
                    variant="secondary"
                    size="sm"
                    className="w-full"
                    disabled
                  >
                    <Pencil aria-hidden="true" />
                    {t("pages.orders.show.edit")}
                  </Button>
                  {order.status !== "confirmed" && (
                    <p className="text-muted-foreground text-xs">
                      {t(
                        `pages.orders.show.cannot_edit.${order.modification_block_reason}`,
                      )}
                    </p>
                  )}
                </div>
              )}
            </CardFooter>
          )}
        </>
      }
    />
  )
}
