import { Settings2 } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogContent,
  AdaptableDialogTitle,
  AdaptableDialogTrigger,
} from "@/components/adaptable-dialog"
import FavoriteButton from "@/components/consumer/menus/favorite-button"
import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import { Label } from "@/components/ui/label"
import { Separator } from "@/components/ui/separator"
import { cn } from "@/lib/utils"
import type { Provider } from "@/types"

interface ProviderFilterOption<Id extends string | number> {
  id: Id
  name: Provider["name"]
}

interface Props<Id extends string | number> {
  providers: ProviderFilterOption<Id>[]
  selectedProviders: Set<Id>
  onApply: (providers: Set<Id>) => void
  selectionMode?: "multiple" | "single"
  allProvidersLabel?: string
  favoriteIds?: Set<Id>
  onToggleFavorite?: (id: Id, isFavorite: boolean) => void
}

export function ProviderFilterSheet<Id extends string | number>({
  providers,
  selectedProviders,
  onApply,
  selectionMode = "multiple",
  allProvidersLabel,
  favoriteIds,
  onToggleFavorite,
}: Props<Id>) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const [draftProviders, setDraftProviders] = useState<Set<Id>>(new Set())

  const allProvidersSelected =
    draftProviders.size === 0 ||
    (selectionMode === "multiple" &&
      providers.every((provider) => draftProviders.has(provider.id)))

  function toggleProvider(providerId: Id) {
    setDraftProviders((selected) => {
      if (selectionMode === "single") {
        return selected.has(providerId) ? new Set() : new Set([providerId])
      }

      const next = new Set(
        selected.size === 0
          ? providers.map((provider) => provider.id)
          : selected,
      )

      if (next.has(providerId)) next.delete(providerId)
      else next.add(providerId)

      return next
    })
  }

  return (
    <AdaptableDialog
      open={open}
      onOpenChange={(nextOpen) => {
        setOpen(nextOpen)
        if (nextOpen) setDraftProviders(new Set(selectedProviders))
      }}
    >
      <AdaptableDialogTrigger asChild>
        <Button
          type="button"
          variant="outline"
          size="icon"
          aria-label={t("pages.consumer_dashboard.index.provider_filter.open")}
          className="border-border bg-card hover:bg-accent ml-auto size-9 shrink-0 rounded-full shadow-none"
        >
          <Settings2 aria-hidden="true" className="size-4" />
        </Button>
      </AdaptableDialogTrigger>

      <AdaptableDialogContent
        showCloseButton={false}
        data-provider-filter-sheet
        className="flex max-h-[90dvh] flex-col gap-5 overflow-hidden p-5"
      >
        <div
          aria-hidden="true"
          className="bg-border mx-auto -mt-3 h-1 w-12 shrink-0 rounded-full md:hidden"
        />
        <AdaptableDialogTitle className="shrink-0 text-base leading-6 font-semibold tracking-normal">
          {t("pages.consumer_dashboard.index.provider_filter.title")}
        </AdaptableDialogTitle>

        <div className="flex min-h-0 flex-1 flex-col">
          <div
            className={cn(
              "border-border bg-card flex min-h-12 shrink-0 items-center gap-3 rounded-lg border p-3",
              allProvidersSelected && "border-primary bg-muted",
            )}
          >
            <Checkbox
              id="dashboard-filter-all"
              checked={allProvidersSelected}
              onCheckedChange={() => setDraftProviders(new Set())}
              className="border-input bg-background text-primary data-[state=checked]:bg-background dark:data-[state=checked]:bg-background [&_[data-slot=checkbox-indicator]]:bg-primary flex items-center justify-center rounded-full shadow-none [&_[data-slot=checkbox-indicator]]:size-2 [&_[data-slot=checkbox-indicator]]:rounded-full [&_svg]:hidden"
            />
            <Label
              htmlFor="dashboard-filter-all"
              className="min-w-0 flex-1 cursor-pointer text-base leading-6 font-medium tracking-normal wrap-anywhere"
            >
              {allProvidersLabel ??
                t("pages.consumer_dashboard.index.provider_filter.all")}
            </Label>
          </div>

          <Separator className="my-2 shrink-0" />
          <div
            data-provider-filter-list
            className="flex min-h-0 flex-col gap-3 overflow-x-hidden overflow-y-auto overscroll-contain p-1"
          >
            {providers.map((provider) => (
              <div
                key={provider.id}
                className={cn(
                  "border-border bg-card flex min-h-12 shrink-0 items-center gap-3 rounded-lg border p-3",
                  (draftProviders.has(provider.id) ||
                    (selectionMode === "multiple" && allProvidersSelected)) &&
                    "border-primary bg-muted",
                )}
              >
                <Checkbox
                  id={`dashboard-filter-${provider.id}`}
                  checked={
                    draftProviders.has(provider.id) ||
                    (selectionMode === "multiple" && allProvidersSelected)
                  }
                  onCheckedChange={() => toggleProvider(provider.id)}
                  className="border-input bg-background text-primary data-[state=checked]:bg-background dark:data-[state=checked]:bg-background [&_[data-slot=checkbox-indicator]]:bg-primary flex items-center justify-center rounded-full shadow-none [&_[data-slot=checkbox-indicator]]:size-2 [&_[data-slot=checkbox-indicator]]:rounded-full [&_svg]:hidden"
                />
                <Label
                  htmlFor={`dashboard-filter-${provider.id}`}
                  className="min-w-0 flex-1 cursor-pointer text-base leading-6 font-medium tracking-normal wrap-anywhere"
                >
                  {provider.name}
                </Label>
                {favoriteIds && onToggleFavorite && (
                  <FavoriteButton
                    active={favoriteIds.has(provider.id)}
                    label={t(
                      `pages.consumer_dashboard.index.favorites.${favoriteIds.has(provider.id) ? "remove" : "add"}`,
                      { name: provider.name },
                    )}
                    onToggle={() =>
                      onToggleFavorite(
                        provider.id,
                        favoriteIds.has(provider.id),
                      )
                    }
                  />
                )}
              </div>
            ))}
          </div>
        </div>

        <div className="grid shrink-0 grid-cols-2 gap-3">
          <Button
            type="button"
            variant="secondary"
            className="bg-secondary text-secondary-foreground hover:bg-secondary/80 hover:text-secondary-foreground h-12 rounded-lg text-base font-medium shadow-none"
            onClick={() => setOpen(false)}
          >
            {t("pages.consumer_dashboard.index.provider_filter.cancel")}
          </Button>
          <Button
            type="button"
            className="bg-primary text-primary-foreground hover:bg-primary/90 h-12 rounded-lg text-base font-medium shadow-none"
            onClick={() => {
              onApply(
                selectionMode === "multiple" && allProvidersSelected
                  ? new Set()
                  : new Set(draftProviders),
              )
              setOpen(false)
            }}
          >
            {t("pages.consumer_dashboard.index.provider_filter.apply")}
          </Button>
        </div>
      </AdaptableDialogContent>
    </AdaptableDialog>
  )
}
