import { SlidersHorizontal } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import { Label } from "@/components/ui/label"
import {
  Popover,
  PopoverContent,
  PopoverTrigger,
} from "@/components/ui/popover"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import { Separator } from "@/components/ui/separator"
import {
  type ConsumerHistoryFilters,
  type SubsidyFilter,
  emptyConsumerHistoryFilters,
  hasConsumerHistoryFilters,
} from "@/lib/admin-consumer-history"
import type { AdminConsumerMonth, PaymentStatus } from "@/types"

interface ConsumerHistoryFiltersProps {
  providers: AdminConsumerMonth["providers"]
  value: ConsumerHistoryFilters
  onApply: (filters: ConsumerHistoryFilters) => void
}

const subsidyFilters: SubsidyFilter[] = ["all", "with", "without"]
const page = "pages.admin.consumers.show.filters"

export default function ConsumerHistoryFiltersPopover({
  providers,
  value,
  onApply,
}: ConsumerHistoryFiltersProps) {
  const { t } = useTranslation()
  const [open, setOpen] = useState(false)
  const [draft, setDraft] = useState<ConsumerHistoryFilters>(() =>
    cloneFilters(value),
  )
  const statuses = [...new Set(providers.map((provider) => provider.status))]

  function toggleProvider(id: number) {
    setDraft((current) => {
      const selected = new Set(current.providers)
      if (selected.has(id)) selected.delete(id)
      else selected.add(id)

      return { ...current, providers: selected }
    })
  }

  return (
    <Popover
      open={open}
      onOpenChange={(nextOpen) => {
        setOpen(nextOpen)
        if (nextOpen) setDraft(cloneFilters(value))
      }}
    >
      <PopoverTrigger asChild>
        <Button
          type="button"
          variant="outline"
          size="icon"
          className="relative rounded-full"
          aria-label={t(`${page}.open`)}
        >
          <SlidersHorizontal aria-hidden="true" />
          {hasConsumerHistoryFilters(value) && (
            <span
              className="bg-primary ring-background absolute -top-0.5 -right-0.5 size-2.5 rounded-full ring-2"
              aria-hidden="true"
            />
          )}
        </Button>
      </PopoverTrigger>

      <PopoverContent
        align="end"
        className="max-h-[min(36rem,var(--radix-popover-content-available-height))] w-[min(22rem,calc(100vw-2rem))] overflow-y-auto p-4"
      >
        <div className="grid gap-4">
          <div className="flex items-center justify-between gap-3">
            <h3 className="font-semibold">{t(`${page}.title`)}</h3>
            {hasConsumerHistoryFilters(draft) && (
              <Button
                type="button"
                variant="ghost"
                size="sm"
                onClick={() => setDraft(emptyConsumerHistoryFilters())}
              >
                {t(`${page}.clear`)}
              </Button>
            )}
          </div>

          <div className="grid gap-2">
            <p className="text-sm font-medium">{t(`${page}.providers`)}</p>
            <div className="grid gap-1">
              <div className="flex items-center gap-2 rounded-md px-2 py-1.5">
                <Checkbox
                  id="consumer-history-provider-all"
                  checked={draft.providers.size === 0}
                  onCheckedChange={() =>
                    setDraft((current) => ({
                      ...current,
                      providers: new Set(),
                    }))
                  }
                />
                <Label
                  htmlFor="consumer-history-provider-all"
                  className="flex-1 cursor-pointer font-normal"
                >
                  {t(`${page}.all_providers`)}
                </Label>
              </div>

              {providers.map((provider) => (
                <div
                  key={provider.id}
                  className="flex items-center gap-2 rounded-md px-2 py-1.5"
                >
                  <Checkbox
                    id={`consumer-history-provider-${provider.id}`}
                    checked={draft.providers.has(provider.id)}
                    onCheckedChange={() => toggleProvider(provider.id)}
                  />
                  <Label
                    htmlFor={`consumer-history-provider-${provider.id}`}
                    className="flex-1 cursor-pointer font-normal"
                  >
                    {provider.name}
                  </Label>
                </div>
              ))}
            </div>
          </div>

          <Separator />

          <div className="grid gap-2">
            <p className="text-sm font-medium">{t(`${page}.status`)}</p>
            <RadioGroup
              value={draft.status}
              onValueChange={(status) =>
                setDraft((current) => ({
                  ...current,
                  status: status as PaymentStatus | "all",
                }))
              }
              className="gap-1"
            >
              <FilterRadio
                id="consumer-history-status-all"
                value="all"
                label={t(`${page}.all_statuses`)}
              />
              {statuses.map((status) => (
                <FilterRadio
                  key={status}
                  id={`consumer-history-status-${status}`}
                  value={status}
                  label={t(`pages.provider_collections.statuses.${status}`)}
                />
              ))}
            </RadioGroup>
          </div>

          <Separator />

          <div className="grid gap-2">
            <p className="text-sm font-medium">{t(`${page}.subsidy`)}</p>
            <RadioGroup
              value={draft.subsidy}
              onValueChange={(subsidy) =>
                setDraft((current) => ({
                  ...current,
                  subsidy: subsidy as SubsidyFilter,
                }))
              }
              className="gap-1"
            >
              {subsidyFilters.map((subsidy) => (
                <FilterRadio
                  key={subsidy}
                  id={`consumer-history-subsidy-${subsidy}`}
                  value={subsidy}
                  label={t(`${page}.subsidy_${subsidy}`)}
                />
              ))}
            </RadioGroup>
          </div>

          <div className="grid grid-cols-2 gap-2 pt-1">
            <Button
              type="button"
              variant="outline"
              onClick={() => setOpen(false)}
            >
              {t(`${page}.cancel`)}
            </Button>
            <Button
              type="button"
              onClick={() => {
                onApply({
                  ...draft,
                  providers:
                    draft.providers.size === providers.length
                      ? new Set<number>()
                      : new Set(draft.providers),
                })
                setOpen(false)
              }}
            >
              {t(`${page}.apply`)}
            </Button>
          </div>
        </div>
      </PopoverContent>
    </Popover>
  )
}

function FilterRadio({
  id,
  value,
  label,
}: {
  id: string
  value: string
  label: string
}) {
  return (
    <div className="flex items-center gap-2 rounded-md px-2 py-1.5">
      <RadioGroupItem id={id} value={value} />
      <Label htmlFor={id} className="flex-1 cursor-pointer font-normal">
        {label}
      </Label>
    </div>
  )
}

function cloneFilters(filters: ConsumerHistoryFilters): ConsumerHistoryFilters {
  return { ...filters, providers: new Set(filters.providers) }
}
