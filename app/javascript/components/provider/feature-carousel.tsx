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
            className="bg-[#FAFAFA] dark:bg-muted w-full shrink-0 snap-center border-0 p-6 rounded-lg text-left shadow-none"
          >
            <CardHeader className="gap-2 p-0">
              <span className="bg-[#E5E5E5] dark:bg-neutral-800 mb-2 flex size-10 items-center justify-center rounded-full text-[#0A0A0A] dark:text-neutral-100">
                <Icon className="size-6" aria-hidden="true" />
              </span>
              <h2 className="text-base font-semibold leading-6 text-[#0A0A0A] dark:text-neutral-100">
                {t(`pages.home.features.${key}.title`)}
              </h2>
              <p className="text-sm font-normal leading-5 text-[#737373] dark:text-neutral-400">
                {t(`pages.home.features.${key}.description`)}
              </p>
            </CardHeader>
          </Card>
        ))}
      </div>

      <div className="flex gap-2">
        {features.map(({ key }, index) => (
          <Button
            key={key}
            type="button"
            variant="ghost"
            size="icon-xs"
            aria-label={t("pages.home.features.go_to", { number: index + 1 })}
            aria-current={index === active}
            onClick={() => goTo(index)}
            className="size-4 p-0 hover:bg-transparent"
          >
            <span
              className={cn(
                "size-3 rounded-full transition-colors",
                index === active
                  ? "bg-[#737373]"
                  : "bg-[#E5E5E5] dark:bg-neutral-800",
              )}
            />
          </Button>
        ))}
      </div>
    </section>
  )
}
