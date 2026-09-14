import { Settings2 } from "lucide-react"
import { useState } from "react"

import { Button } from "@/components/ui/button"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet"

interface Props {
  providers: string[]
  provider: string
  setProvider: (value: string) => void
}

export function ProviderFilterSheet({
  providers,
  provider,
  setProvider,
}: Props) {
  const [open, setOpen] = useState(false)
  const [draftProvider, setDraftProvider] = useState(provider)
  const options = ["all", ...providers]

  return (
    <Sheet
      open={open}
      onOpenChange={(nextOpen) => {
        setOpen(nextOpen)
        if (nextOpen) setDraftProvider(provider)
      }}
    >
      <SheetTrigger asChild>
        <Button
          type="button"
          variant="outline"
          size="icon"
          aria-label="Cambiar proveedor"
          className="size-8 rounded-full bg-white md:hidden"
        >
          <Settings2 aria-hidden="true" className="size-4" />
        </Button>
      </SheetTrigger>
      <SheetContent
        side="bottom"
        showCloseButton={false}
        className="gap-0 rounded-t-3xl border-0 bg-white px-6 pt-3 pb-6 text-[#171717] md:hidden"
      >
        <div className="mx-auto mb-5 h-1 w-10 rounded-full bg-[#d9d9d9]" />
        <SheetTitle className="text-base font-bold text-[#171717]">
          Filtrar por Proveedores
        </SheetTitle>
        <SheetDescription className="sr-only">
          Seleccioná el proveedor que querés ver en el menú.
        </SheetDescription>
        <RadioGroup
          value={draftProvider}
          onValueChange={setDraftProvider}
          className="mt-4 gap-0"
        >
          {options.map((providerName) => (
            <label
              key={providerName}
              className="flex h-12 cursor-pointer items-center gap-3 text-sm"
            >
              <RadioGroupItem value={providerName} />
              {providerName === "all" ? "Todos" : providerName}
            </label>
          ))}
        </RadioGroup>
        <div className="mt-5 grid grid-cols-2 gap-3">
          <Button
            type="button"
            variant="secondary"
            className="h-12 rounded-lg"
            onClick={() => setOpen(false)}
          >
            Cancelar
          </Button>
          <Button
            type="button"
            className="h-12 rounded-lg bg-[#171717] text-white hover:bg-[#171717]/90"
            onClick={() => {
              setProvider(draftProvider)
              setOpen(false)
            }}
          >
            Aplicar
          </Button>
        </div>
      </SheetContent>
    </Sheet>
  )
}
