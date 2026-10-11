import { router } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import {
  Sheet,
  SheetContent,
  SheetDescription,
  SheetFooter,
  SheetHeader,
  SheetTitle,
} from "@/components/ui/sheet"

interface Props {
  open: boolean
  title: string
  description: string
  href: string
}

export default function CompletedSheet({
  open,
  title,
  description,
  href,
}: Props) {
  const { t } = useTranslation()
  const done = () => router.visit(href)

  return (
    <Sheet open={open} onOpenChange={done}>
      <SheetContent
        side="bottom"
        showCloseButton={false}
        className="mx-auto w-full max-w-md rounded-t-3xl p-6"
      >
        <SheetHeader className="p-0">
          <SheetTitle>{title}</SheetTitle>
          <SheetDescription>{description}</SheetDescription>
        </SheetHeader>
        <SheetFooter className="p-0">
          <Button type="button" size="lg" onClick={done}>
            {t("components.completed_sheet.done")}
          </Button>
        </SheetFooter>
      </SheetContent>
    </Sheet>
  )
}
