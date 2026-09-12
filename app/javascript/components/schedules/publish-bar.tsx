import { Button } from "@/components/ui/button"
//vista previa de publicacion
interface PublishBarProps {
  selectedCount: number
  processing: boolean
  onPublish: () => void
}

export default function PublishBar({
  selectedCount,
  processing,
  onPublish,
}: PublishBarProps) {
  return (
    <div className="sticky bottom-0 flex items-center justify-between border-t bg-background p-4">
      <p className="text-sm text-muted-foreground">
        {selectedCount === 0
          ? "No seleccionaste ningún plato."
          : `${selectedCount} plato${selectedCount === 1 ? "" : "s"} seleccionado${selectedCount === 1 ? "" : "s"}.`}
      </p>

      <Button disabled={selectedCount === 0 || processing} onClick={onPublish}>
        {processing ? "Publicando..." : "Publicar menú"}
      </Button>
    </div>
  )
}
