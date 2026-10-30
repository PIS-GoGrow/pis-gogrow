import { Link } from "@inertiajs/react"
import { ChevronLeft } from "lucide-react"
import type { PropsWithChildren, ReactNode } from "react"

import AppLogoIcon from "@/components/app-logo-icon"
import { home } from "@/routes"

interface AuthLayoutProps {
  name?: string
  title?: string
  description?: ReactNode
  backHref?: string
  hideLogo?: boolean
  variant?: "welcome" | "form"
}

export default function AuthSimpleLayout({
  children,
  title,
  description,
  backHref,
  hideLogo,
  variant = "welcome",
}: PropsWithChildren<AuthLayoutProps>) {
  const isForm = variant === "form"
  const shouldHideLogo = hideLogo ?? isForm

  return (
    <div className="bg-background flex min-h-svh flex-col items-center justify-center gap-6 p-6 md:p-10">
      <div className="w-full max-w-[354px]">
        <div className="flex flex-col gap-6">
          {backHref && (
            <div>
              <Link
                href={backHref}
                aria-label="Volver"
                className="inline-flex size-6 items-center justify-center text-foreground transition-opacity hover:opacity-70"
              >
                <ChevronLeft className="size-5" />
              </Link>
            </div>
          )}

          <div
            className={`flex flex-col ${isForm ? "items-start text-left gap-2" : "items-center text-center gap-4"}`}
          >
            {!shouldHideLogo && (
              <Link
                href={home.index()}
                className="flex flex-col items-center gap-2 font-medium"
              >
                <div className="mb-2 flex size-20 items-center justify-center rounded-[22px] bg-[#0A0A0A] text-[#FAFAFA] dark:bg-white dark:text-black">
                  <AppLogoIcon size={48} />
                </div>
                <span className="sr-only">{title}</span>
              </Link>
            )}

            <div
              className={`flex flex-col gap-2 ${isForm ? "text-left" : "text-center"}`}
            >
              <h1
                className={
                  isForm
                    ? "text-2xl font-bold leading-8 text-[#0A0A0A] dark:text-neutral-100"
                    : "text-[30px] font-bold leading-9 tracking-tight text-[#0A0A0A] dark:text-neutral-100"
                }
              >
                {title}
              </h1>
              <div
                className={
                  isForm
                    ? "space-y-3 text-base font-normal leading-6 text-[#737373] dark:text-neutral-400"
                    : "text-base font-normal leading-6 text-[#737373] opacity-80 dark:text-neutral-400"
                }
              >
                {typeof description === "string" ? (
                  description.includes("\n\n") ? (
                    description.split("\n\n").map((paragraph, index) => (
                      <p key={index}>{paragraph}</p>
                    ))
                  ) : (
                    <p>{description}</p>
                  )
                ) : (
                  description
                )}
              </div>
            </div>
          </div>

          {children}
        </div>
      </div>
    </div>
  )
}
