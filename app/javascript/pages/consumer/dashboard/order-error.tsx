import { Link } from "@inertiajs/react"
import { X } from "lucide-react"

import { Button } from "@/components/ui/button"

interface Props {
  retry: () => void
  homeUrl: string
}

export function OrderError({ retry, homeUrl }: Props) {
  return (
    <div className="mx-auto flex min-h-screen max-w-3xl flex-col bg-white px-6 py-8 text-[#151515] md:my-8 md:min-h-0 md:rounded-2xl md:border md:border-[#e5e5e5] md:p-8">
      <div className="flex flex-1 flex-col items-center justify-center pb-16">
        <div className="flex size-20 items-center justify-center rounded-full bg-[#171717] text-white">
          <X aria-hidden="true" className="size-10" strokeWidth={2.5} />
        </div>
        <h1 className="mt-7 text-center text-2xl font-bold">
          ¡Ups! Algo salió mal
        </h1>
        <p className="mt-2 max-w-sm text-center text-base leading-6 text-[#888]">
          Hubo un problema al procesar tu pedido. Intentá de nuevo.
        </p>
      </div>

      <div className="space-y-3">
        <Button
          type="button"
          onClick={retry}
          className="h-12 w-full bg-black text-white hover:bg-black/85 hover:text-white"
        >
          Reintentar
        </Button>
        <Button
          asChild
          type="button"
          variant="secondary"
          className="h-12 w-full bg-[#f5f5f5] text-[#151515] hover:bg-[#ececec]"
        >
          <Link href={homeUrl} preserveState={false}>
            Volver a Menú
          </Link>
        </Button>
      </div>
    </div>
  )
}
