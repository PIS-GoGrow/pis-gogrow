import { Link } from "@inertiajs/react"
import { X } from "lucide-react"

import { Button } from "@/components/ui/button"
import { MobileCard, BottomAction } from "@/components/consumer/mobile-card"

interface Props {
  retry: () => void
  homeUrl: string
}

export function OrderError({ retry, homeUrl }: Props) {
  return (
    <div className="bg-background border-border text-foreground mx-auto flex min-h-screen max-w-3xl flex-col px-6 py-8 md:my-8 md:min-h-0 md:rounded-2xl md:border md:p-8">
      <div className="flex flex-1 flex-col items-center justify-center pb-16">
        <div className="bg-primary text-primary-foreground flex size-20 items-center justify-center rounded-full">
          <X aria-hidden="true" className="size-10" strokeWidth={2.5} />
        </div>
        <h1 className="mt-7 text-center text-2xl font-bold">
          ¡Ups! Algo salió mal
        </h1>
        <p className="text-muted-foreground mt-2 max-w-sm text-center text-base leading-6">
          Hubo un problema al procesar tu pedido. Intentá de nuevo.
        </p>
      </div>

      <div className="space-y-3">
        <Button
          type="button"
          onClick={retry}
          className="bg-primary text-primary-foreground hover:bg-primary/90 hover:text-primary-foreground h-12 w-full"
        >
          Reintentar
        </Button>
        <Button
          asChild
          type="button"
          variant="secondary"
          className="bg-secondary text-secondary-foreground hover:bg-secondary/80 hover:text-secondary-foreground h-12 w-full"
        >
          <Link href={homeUrl} preserveState={false}>
            Volver a Menú
          </Link>
        </Button>
      </div>
    </div>
  )
}
