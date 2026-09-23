import { Edit2 } from "lucide-react"

import { Button } from "@/components/ui/button"
//vista previa de publicacion
interface PublishBarProps {
  dateLabel: string
  statusLabel: string
  canPublish: boolean
  canEdit?: boolean
  selectedCount: number
  processing: boolean
  onPublish: () => void
  onEdit?: () => void
}

export default function PublishBar({
  dateLabel,
  statusLabel,
  canPublish,
  canEdit,
  selectedCount,
  processing,
  onPublish,
  onEdit,
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

      {!canPublish && canEdit && (
        <Button variant="outline" onClick={onEdit}>
          <Edit2 className="mr-2 size-4" />
          Editar menú
        </Button>
      )}
    </div>
  )
}