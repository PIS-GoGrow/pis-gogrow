import { Badge } from "@/components/ui/badge"
import { Card, CardContent } from "@/components/ui/card"

//schedules a publicar

interface PublishedSchedule {
  id: number
  amount: number
  menu: { id: number; name: string }
}

interface PublishedDayViewProps {
  schedules: PublishedSchedule[]
}

export default function PublishedDayView({
  schedules,
}: PublishedDayViewProps) {
  return (
    <Card>
      <CardContent className="flex flex-col gap-3">
        <Badge variant="secondary" className="w-fit bg-green-100 text-green-700">
          Publicado
        </Badge>

        {schedules.map((schedule) => (
          <div
            key={schedule.id}
            className="flex items-center justify-between border-b py-2 last:border-b-0"
          >
            <p className="font-medium">{schedule.menu.name}</p>
            <p className="text-sm text-muted-foreground">
              Stock: {schedule.amount}
            </p>
          </div>
        ))}
      </CardContent>
    </Card>
  )
}