import { Check, Settings2 } from "lucide-react"
import { Checkbox as CheckboxPrimitive } from "radix-ui"
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

interface OptionProps {
  id: string
  label: string
  checked: boolean
  onToggle: () => void
}

function Option({ id, label, checked, onToggle }: OptionProps) {
  return (
    <CheckboxPrimitive.Root
      id={id}
      checked={checked}
      onCheckedChange={onToggle}
      aria-labelledby={`${id}-label`}
      className="hover:bg-muted focus-visible:ring-ring/50 flex min-h-12 min-w-0 flex-1 items-center gap-2 rounded-lg px-2 text-left text-base leading-6 font-medium tracking-normal outline-none focus-visible:ring-[3px]"
    >
      <span className="flex size-6 shrink-0 items-center justify-center">
        <CheckboxPrimitive.Indicator>
          <Check aria-hidden="true" className="size-4" />
        </CheckboxPrimitive.Indicator>
      </span>
      <span id={`${id}-label`} className="min-w-0 flex-1 wrap-anywhere">
        {label}
      </span>
    </CheckboxPrimitive.Root>
  )
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

  const allProvidersSelected = draftProviders.size === 0

  function toggleProvider(providerId: Id) {
    setDraftProviders((selected) => {
      if (selectionMode === "single") {
        return selected.has(providerId) ? new Set() : new Set([providerId])
      }

      const next = new Set(selected)

      if (next.has(providerId)) next.delete(providerId)
      else next.add(providerId)

      return providers.every((provider) => next.has(provider.id))
        ? new Set()
        : next
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
        <AdaptableDialogTitle className="shrink-0 text-base leading-6 font-semibold tracking-normal">
          {t("pages.consumer_dashboard.index.provider_filter.title")}
        </AdaptableDialogTitle>

        <div
          data-provider-filter-list
          className="-mx-2 flex min-h-0 flex-1 flex-col overflow-x-hidden overflow-y-auto overscroll-contain"
        >
          <Option
            id="dashboard-filter-all"
            label={
              allProvidersLabel ??
              t("pages.consumer_dashboard.index.provider_filter.all")
            }
            checked={allProvidersSelected}
            onToggle={() => setDraftProviders(new Set())}
          />
          {providers.map((provider) => (
            <div key={provider.id} className="flex items-center gap-1">
              <Option
                id={`dashboard-filter-${provider.id}`}
                label={provider.name}
                checked={draftProviders.has(provider.id)}
                onToggle={() => toggleProvider(provider.id)}
              />
              {favoriteIds && onToggleFavorite && (
                <FavoriteButton
                  active={favoriteIds.has(provider.id)}
                  label={t(
                    `pages.consumer_dashboard.index.favorites.${favoriteIds.has(provider.id) ? "remove" : "add"}`,
                    { name: provider.name },
                  )}
                  onToggle={() =>
                    onToggleFavorite(provider.id, favoriteIds.has(provider.id))
                  }
                />
              )}
            </div>
          ))}
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
              onApply(new Set(draftProviders))
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
