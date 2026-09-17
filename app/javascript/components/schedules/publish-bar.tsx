import { Button } from "@/components/ui/button"
//vista previa de publicacion
interface PublishBarProps {
  dateLabel: string
  statusLabel: string
  canPublish: boolean
  selectedCount: number
  processing: boolean
  onPublish: () => void
}

export default function PublishBar({
  dateLabel,
  statusLabel,
  canPublish,
  selectedCount,
  processing,
  onPublish,
}: PublishBarProps) {
  return (
    <div className="bg-card flex items-center justify-between rounded-xl border p-4">
      <div>
        <p className="font-medium capitalize">{dateLabel}</p>
        <p className="text-muted-foreground text-sm">{statusLabel}</p>
      </div>

      {canPublish && (
        <Button
          disabled={selectedCount === 0 || processing}
          onClick={onPublish}
        >
          {processing ? "Publicando..." : "Publicar menú"}
        </Button>
      )}
    </div>
  )
}
