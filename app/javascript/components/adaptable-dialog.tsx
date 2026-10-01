import * as React from "react"

import {
  Dialog,
  DialogClose,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog"
import {
  Sheet,
  SheetClose,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
  SheetTrigger,
} from "@/components/ui/sheet"
import { useIsMobile } from "@/hooks/use-mobile"
import { cn } from "@/lib/utils"

/**
 * Cómo se comporta el componente en desktop.
 * En mobile SIEMPRE es un Sheet con side="bottom".
 */
export type AdaptableDialogDesktopVariant = "dialog" | "sheet"

type Mode = "dialog" | "sheet-right" | "sheet-bottom"

const AdaptableDialogContext = React.createContext<Mode | null>(null)

function useMode(): Mode {
  const mode = React.useContext(AdaptableDialogContext)
  if (!mode) {
    throw new Error(
      "Los componentes AdaptableDialog* deben usarse dentro de <AdaptableDialog>",
    )
  }
  return mode
}

/* -------------------------------------------------------------------------- */
/* Root                                                                       */
/* -------------------------------------------------------------------------- */

type AdaptableDialogProps = React.ComponentProps<typeof Dialog> & {
  /** Qué usar cuando NO es mobile. Default: "dialog". */
  desktopVariant?: AdaptableDialogDesktopVariant
}

function AdaptableDialog({
  desktopVariant = "dialog",
  ...props
}: AdaptableDialogProps) {
  const isMobile = useIsMobile()

  const mode: Mode = isMobile
    ? "sheet-bottom"
    : desktopVariant === "sheet"
      ? "sheet-right"
      : "dialog"

  // Sheet y Dialog de shadcn son ambos el Root de Radix Dialog, así que
  // comparten las mismas props (open, onOpenChange, defaultOpen, modal).
  const Root = mode === "dialog" ? Dialog : Sheet

  return (
    <AdaptableDialogContext.Provider value={mode}>
      <Root {...props} />
    </AdaptableDialogContext.Provider>
  )
}

/* -------------------------------------------------------------------------- */
/* Trigger / Close                                                            */
/* -------------------------------------------------------------------------- */

function AdaptableDialogTrigger(
  props: React.ComponentProps<typeof DialogTrigger>,
) {
  const mode = useMode()
  const Comp = mode === "dialog" ? DialogTrigger : SheetTrigger
  return <Comp {...props} />
}

function AdaptableDialogClose(props: React.ComponentProps<typeof DialogClose>) {
  const mode = useMode()
  const Comp = mode === "dialog" ? DialogClose : SheetClose
  return <Comp {...props} />
}

/* -------------------------------------------------------------------------- */
/* Content                                                                    */
/* -------------------------------------------------------------------------- */

function AdaptableDialogContent({
  className,
  ...props
}: React.ComponentProps<typeof DialogContent>) {
  const mode = useMode()

  if (mode === "dialog") {
    return <DialogContent className={className} {...props} />
  }

  // DialogContent y SheetContent comparten las props de Radix (children,
  // onOpenAutoFocus, onEscapeKeyDown, etc.), por eso el cast es seguro.
  const sheetProps = props as React.ComponentProps<typeof SheetContent>

  if (mode === "sheet-bottom") {
    return (
      <SheetContent
        side="bottom"
        // Evita que el sheet tape toda la pantalla y permite scroll interno
        className={cn("max-h-[90dvh] overflow-y-auto rounded-t-xl", className)}
        {...sheetProps}
      />
    )
  }

  return <SheetContent side="right" className={className} {...sheetProps} />
}

/* -------------------------------------------------------------------------- */
/* Header / Footer / Title / Description                                      */
/* -------------------------------------------------------------------------- */

function AdaptableDialogHeader(
  props: React.ComponentProps<typeof DialogHeader>,
) {
  const mode = useMode()
  const Comp = mode === "dialog" ? DialogHeader : SheetHeader
  return <Comp {...props} />
}

function AdaptableDialogFooter(
  props: React.ComponentProps<typeof DialogFooter>,
) {
  const mode = useMode()
  const Comp = mode === "dialog" ? DialogFooter : SheetFooter
  return <Comp {...props} />
}

function AdaptableDialogTitle(props: React.ComponentProps<typeof DialogTitle>) {
  const mode = useMode()
  const Comp = mode === "dialog" ? DialogTitle : SheetTitle
  return <Comp {...props} />
}

function AdaptableDialogDescription(
  props: React.ComponentProps<typeof DialogDescription>,
) {
  const mode = useMode()
  const Comp = mode === "dialog" ? DialogDescription : SheetDescription
  return <Comp {...props} />
}

export {
  AdaptableDialog,
  AdaptableDialogClose,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogFooter,
  AdaptableDialogHeader,
  AdaptableDialogTitle,
  AdaptableDialogTrigger,
}
