import { SlidersHorizontal } from "lucide-react"
import { useState } from "react"

import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import { Label } from "@/components/ui/label"
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet"

interface Props {
  providers: string[]
  selectedProviders: Set<string>
  onApply: (providers: Set<string>) => void
}

export function ProviderFilterSheet({
  providers,
  selectedProviders,
  onApply,
}: Props) {
  const [open, setOpen] = useState(false)
  const [draftProviders, setDraftProviders] = useState<Set<string>>(new Set())

  function toggleProvider(provider: string) {
    setDraftProviders((selected) => {
      const next = new Set(selected)

      if (next.has(provider)) next.delete(provider)
      else next.add(provider)

      return next
    })
  }

  return (
    <Sheet
      open={open}
      onOpenChange={(nextOpen) => {
        setOpen(nextOpen)
        if (nextOpen) setDraftProviders(new Set(selectedProviders))
      }}
    >
      <SheetTrigger asChild>
        <Button
          type="button"
          variant="outline"
          size="icon"
          aria-label="Filtrar por proveedores"
          className="ml-auto size-9 shrink-0 rounded-full border-[#E5E5E5] bg-white shadow-none hover:bg-white dark:border-[#E5E5E5] dark:bg-white dark:hover:bg-white"
        >
          <SlidersHorizontal aria-hidden="true" className="size-4" />
        </Button>
      </SheetTrigger>

      <SheetContent
        side="bottom"
        showCloseButton={false}
        data-provider-filter-sheet
        className="gap-6 rounded-t-[32px] border border-[#E5E5E5] bg-white px-6 pt-2.5 pb-8 text-[#0A0A0A] shadow-none md:inset-x-1/2 md:bottom-1/2 md:w-[402px] md:translate-x-[-50%] md:translate-y-1/2 md:rounded-[32px]"
      >
        <div
          aria-hidden="true"
          className="mx-auto h-1 w-12 rounded-full bg-[#E5E5E5]"
        />

        <div className="flex flex-col gap-5">
          <SheetTitle className="text-base leading-6 font-semibold tracking-normal text-[#0A0A0A]">
            Filtrar por Proveedores
          </SheetTitle>
          <SheetDescription className="sr-only">
            Seleccioná los proveedores que querés ver en el menú.
          </SheetDescription>

          <div className="flex flex-col">
            <div className="flex h-12 items-center gap-3 rounded-sm px-2 py-3">
              <Checkbox
                id="dashboard-filter-all"
                checked={draftProviders.size === 0}
                onCheckedChange={() => setDraftProviders(new Set())}
                className="size-4 rounded-none border-0 bg-transparent shadow-none focus-visible:border-transparent focus-visible:ring-0 data-[state=checked]:border-transparent data-[state=checked]:bg-transparent data-[state=checked]:text-[#0A0A0A] dark:bg-transparent dark:data-[state=checked]:bg-transparent [&_svg]:size-4"
              />
              <Label
                htmlFor="dashboard-filter-all"
                className="flex-1 cursor-pointer text-base leading-6 font-medium tracking-normal"
              >
                Todos
              </Label>
            </div>

            {providers.map((provider) => (
              <div
                key={provider}
                className="flex h-12 items-center gap-3 rounded-sm px-2 py-3"
              >
                <Checkbox
                  id={`dashboard-filter-${provider}`}
                  checked={draftProviders.has(provider)}
                  onCheckedChange={() => toggleProvider(provider)}
                  className="size-4 rounded-none border-0 bg-transparent shadow-none focus-visible:border-transparent focus-visible:ring-0 data-[state=checked]:border-transparent data-[state=checked]:bg-transparent data-[state=checked]:text-[#0A0A0A] dark:bg-transparent dark:data-[state=checked]:bg-transparent [&_svg]:size-4"
                />
                <Label
                  htmlFor={`dashboard-filter-${provider}`}
                  className="flex-1 cursor-pointer text-base leading-6 font-medium tracking-normal"
                >
                  {provider}
                </Label>
              </div>
            ))}
          </div>

          <div className="grid grid-cols-2 gap-3">
            <Button
              type="button"
              variant="secondary"
              className="h-12 rounded-lg bg-neutral-100 text-base font-medium text-black shadow-none hover:bg-neutral-100/80 hover:text-black dark:text-black"
              onClick={() => setOpen(false)}
            >
              Cancelar
            </Button>
            <Button
              type="button"
              className="h-12 rounded-lg bg-[#171717] text-base font-medium text-white shadow-none hover:bg-[#171717]/90"
              onClick={() => {
                onApply(new Set(draftProviders))
                setOpen(false)
              }}
            >
              Aplicar
            </Button>
          </div>
        </div>
      </SheetContent>
    </Sheet>
  )
}
