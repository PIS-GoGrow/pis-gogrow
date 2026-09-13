import { Link } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardAction,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { consumerMenus } from "@/routes"
import type { ConsumerMenu } from "@/types"

interface AvailableMenuCardProps {
  menu: ConsumerMenu
  showLink?: boolean
}

const priceFormat = new Intl.NumberFormat("es-UY", {
  style: "currency",
  currency: "UYU",
  maximumFractionDigits: 0,
})

// Schedule dates are calendar days: format in UTC so SSR and the browser agree.
const dateFormat = new Intl.DateTimeFormat("es-UY", {
  weekday: "short",
  day: "numeric",
  month: "short",
  timeZone: "UTC",
})

export default function AvailableMenuCard({
  menu,
  showLink = false,
}: AvailableMenuCardProps) {
  const { t } = useTranslation()

  return (
    <Card className="w-full">
      <CardHeader>
        <CardTitle>{menu.name}</CardTitle>
        <CardDescription>
          {menu.provider_name &&
            t("pages.consumer.menus.provider", { name: menu.provider_name })}
        </CardDescription>
        {showLink && (
          <CardAction>
            <Button variant="outline" asChild>
              <Link href={consumerMenus.show(menu.id)}>
                {t("pages.consumer.menus.view")}
              </Link>
            </Button>
          </CardAction>
        )}
      </CardHeader>
      <CardContent className="grid gap-3">
        {menu.description && <p className="text-sm">{menu.description}</p>}
        <strong className="text-lg">
          {priceFormat.format(Number(menu.price))}
        </strong>
        <ul className="flex flex-wrap gap-2">
          {menu.schedules.map((schedule) => (
            <li key={schedule.id}>
              <Badge variant="secondary">
                {schedule.date && dateFormat.format(new Date(schedule.date))}
                {" · "}
                {t("pages.consumer.menus.spots", { count: schedule.amount })}
              </Badge>
            </li>
          ))}
        </ul>
      </CardContent>
    </Card>
  )
}
