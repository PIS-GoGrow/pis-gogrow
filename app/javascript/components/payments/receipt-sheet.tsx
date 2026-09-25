import type { ReactNode } from "react"

import {
  Sheet,
  SheetContent,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet"

interface ReceiptSheetProps {
  children: ReactNode
  receiptUrl: string
  contentType?: string | null
  filename?: string
}

export default function ReceiptSheet({
  children,
  receiptUrl,
  contentType,
  filename,
}: ReceiptSheetProps) {
  return (
    <Sheet>
      {children}

      <SheetContent side="right" className="gap-4 sm:max-w-lg">
        <SheetHeader>
          <SheetTitle>
            {filename ? `Comprobante de ${filename}` : "Comprobante de pago"}
          </SheetTitle>
        </SheetHeader>

        <div className="bg-background mx-4 mb-4 overflow-hidden rounded-md border">
          {contentType?.startsWith("image/") ? (
            <img
              src={receiptUrl}
              alt="Comprobante de pago"
              className="max-h-[75vh] w-full object-contain"
            />
          ) : (
            <iframe
              src={receiptUrl}
              title="Comprobante de pago"
              className="h-[75vh] w-full"
            />
          )}
        </div>
      </SheetContent>
    </Sheet>
  )
}
