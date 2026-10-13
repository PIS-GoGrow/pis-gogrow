import { Head } from "@inertiajs/react"
import { CreditCard, ShoppingBag, Utensils } from "lucide-react"
import { useRef, useState } from "react"
import { useTranslation } from "react-i18next"

import AppLogoIcon from "@/components/app-logo-icon"
import { GoogleMark } from "@/components/branding/google-mark"
import DevLoginForm from "@/components/dev-login-form"
import { Button } from "@/components/ui/button"
import { Card, CardHeader } from "@/components/ui/card"
import { cn, readAuthenticityToken } from "@/lib/utils"
import type { HomeIndex } from "@/types"

const features = [
  { key: "menu", icon: Utensils },
  { key: "orders", icon: ShoppingBag },
  { key: "collections", icon: CreditCard },
] as const

export default function Home({ variant, dev_login_enabled }: HomeIndex) {
  const { t } = useTranslation()

  return (
    <>
      <Head title={t("pages.home.title")} />

      <div className="bg-background flex min-h-svh flex-col p-6">
        <main className="mx-auto flex w-full max-w-sm flex-1 flex-col items-center justify-center gap-8 py-10 text-center">
          <div className="flex flex-col items-center gap-4">
            <div className="flex size-24 items-center justify-center rounded-3xl bg-black text-white dark:bg-white dark:text-black">
              <AppLogoIcon size={56} strokeWidth={1.6} />
            </div>
            <h1 className="text-3xl font-bold tracking-tight text-balance">
              {t(`pages.home.${variant}.heading`)}
            </h1>
            <p className="text-muted-foreground">
              {t(`pages.home.${variant}.description`)}
            </p>
          </div>

          {variant === "provider" && <FeatureCarousel />}
        </main>

        <div className="mx-auto flex w-full max-w-sm flex-col gap-6">
          {variant === "provider" ? (
            <Button asChild size="lg" className="h-12 w-full text-base">
              <a href="/provider">{t(`pages.home.${variant}.sign_in`)}</a>
            </Button>
          ) : (
            /*
              Full-page navigation (not an Inertia visit): OmniAuth needs to
              redirect the whole browser to accounts.google.com, and
              omniauth-rails_csrf_protection requires the request to be a POST.
            */
            <form action="/auth/google_oauth2" method="post">
              <input
                type="hidden"
                name="authenticity_token"
                value={readAuthenticityToken()}
              />
              <Button type="submit" size="lg" className="h-12 w-full text-base">
                <GoogleMark />
                {t(`pages.home.${variant}.sign_in`)}
              </Button>
            </form>
          )}

          {dev_login_enabled && <DevLoginForm />}
        </div>
      </div>
    </>
  )
}

function FeatureCarousel() {
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
