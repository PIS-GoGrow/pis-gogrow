import { CreditCard, ShoppingBag, Utensils } from "lucide-react"
import { useRef, useState } from "react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import { Card, CardHeader } from "@/components/ui/card"
import { cn } from "@/lib/utils"

const features = [
  { key: "menu", icon: Utensils },
  { key: "orders", icon: ShoppingBag },
  { key: "collections", icon: CreditCard },
] as const

export default function FeatureCarousel() {
  const { t } = useTranslation()
  const track = useRef<HTMLDivElement>(null)
  const [active, setActive] = useState(0)

  const goTo = (index: number) => {
    const element = track.current
    if (!element) return
    element.scrollTo({ left: index * element.clientWidth, behavior: "smooth" })
  }

  return (
    <section
      aria-roledescription="carousel"
      aria-label={t("pages.home.features.label")}
      className="flex w-full flex-col items-center gap-3"
    >
      <div
        ref={track}
        onScroll={(event) =>
          setActive(
            Math.round(
              event.currentTarget.scrollLeft / event.currentTarget.clientWidth,
            ),
          )
        }
        className="flex w-full snap-x snap-mandatory [scrollbar-width:none] overflow-x-auto [&::-webkit-scrollbar]:hidden"
      >
        {features.map(({ key, icon: Icon }) => (
          <Card
            key={key}
            aria-roledescription="slide"
            className="bg-muted w-full shrink-0 snap-center border-0 py-8 text-left shadow-none"
          >
            <CardHeader className="gap-2 px-8">
              <span className="bg-foreground/10 mb-4 flex size-12 items-center justify-center rounded-full">
                <Icon className="size-6" aria-hidden="true" />
              </span>
              <h2 className="text-lg font-semibold">
                {t(`pages.home.features.${key}.title`)}
              </h2>
              <p className="text-muted-foreground">
                {t(`pages.home.features.${key}.description`)}
              </p>
            </CardHeader>
          </Card>
        ))}
      </div>

      <div className="flex gap-1">
        {features.map(({ key }, index) => (
          <Button
            key={key}
            type="button"
            variant="ghost"
            size="icon-xs"
            aria-label={t("pages.home.features.go_to", { number: index + 1 })}
            aria-current={index === active}
            onClick={() => goTo(index)}
          >
            <span
              className={cn(
                "size-2.5 rounded-full",
                index === active
                  ? "bg-foreground/60"
                  : "bg-muted-foreground/25",
              )}
            />
          </Button>
        ))}
      </div>
    </section>
  )
}
