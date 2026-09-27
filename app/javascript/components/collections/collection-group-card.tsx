import {
  Building2,
  ChevronDown,
  CircleCheck,
  TriangleAlert,
  Users,
} from "lucide-react"
import type { LucideIcon } from "lucide-react"
import type { ReactNode } from "react"
import { useTranslation } from "react-i18next"

import CollectionAccountPanel from "@/components/collections/collection-account-panel"
import StatusBadge from "@/components/status-badge"
import { Avatar, AvatarFallback } from "@/components/ui/avatar"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from "@/components/ui/collapsible"
import { Progress } from "@/components/ui/progress"
import { Separator } from "@/components/ui/separator"
import { useFormatters } from "@/hooks/use-formatters"
import { useInitials } from "@/hooks/use-initials"
import type { PaymentStatus, ProviderCollectionGroup } from "@/types"

interface CollectionGroupCardProps {
  group: ProviderCollectionGroup
  // En el historial todo está confirmado, así que cada empleado muestra la
  // fecha en que pagó en lugar de su estado.
  settled?: boolean
}

function Chevron() {
  return (
    <ChevronDown
      className="text-muted-foreground size-4 shrink-0 transition-transform group-data-[state=open]:rotate-180"
      aria-hidden="true"
    />
  )
}

function OwnerGroup({
  icon: Icon,
  title,
  status,
  amount,
  children,
}: {
  icon: LucideIcon
  title: string
  status: PaymentStatus | null
  amount: number
  children: ReactNode
}) {
  const { formatMoney } = useFormatters()

  return (
    <Collapsible>
      <CollapsibleTrigger className="group flex w-full items-center gap-3 py-2 text-left">
        <span className="flex size-10 shrink-0 items-center justify-center rounded-full bg-blue-100 text-blue-700 dark:bg-blue-950 dark:text-blue-300">
          <Icon className="size-5" aria-hidden="true" />
        </span>

        <span className="grid flex-1 justify-items-start gap-1">
          <span className="text-sm font-semibold">{title}</span>
          <StatusBadge status={status} kind="payment" />
        </span>

        <span className="font-semibold">{formatMoney(amount)}</span>
        <Chevron />
      </CollapsibleTrigger>

      <CollapsibleContent className="grid gap-2 pt-2">
        {children}
      </CollapsibleContent>
    </Collapsible>
  )
}

export default function CollectionGroupCard({
  group,
  settled = false,
}: CollectionGroupCardProps) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()
  const getInitials = useInitials()

  const accounts = [
    ...(group.company ? [group.company] : []),
    ...group.employees,
  ]

  const amountsByStatus: Record<PaymentStatus, number> = {
    pending: 0,
    submitted: 0,
    approved: 0,
    rejected: 0,
  }

  accounts.forEach((account) => {
    if (account.status) {
      amountsByStatus[account.status] += account.amount
    }
  })

  const employeeStatuses = group.employees.map((employee) => employee.status)

  const employeesStatus =
    employeeStatuses.length > 0 &&
    employeeStatuses.every((status) => status === employeeStatuses[0])
      ? employeeStatuses[0]
      : null

  const progress =
    group.total > 0 ? (amountsByStatus.approved / group.total) * 100 : 0

  return (
    <Card className="gap-4 py-4">
      <CardHeader className="px-4">
        <div className="flex items-center gap-3">
          <Avatar size="lg">
            <AvatarFallback className="text-foreground text-xs font-semibold">
              {getInitials(group.client_name)}
            </AvatarFallback>
          </Avatar>

          <CardTitle className="text-lg">{group.client_name}</CardTitle>
        </div>
      </CardHeader>

      <CardContent className="grid gap-4 px-4">
        <div className="grid gap-2">
          <div className="flex items-center justify-between gap-2">
            <span className="text-muted-foreground text-sm">
              {t("pages.provider_collections.group.total")}
            </span>

            <Badge variant="secondary">{group.month}</Badge>
          </div>

          <p>
            <strong className="text-2xl">{formatMoney(group.total)}</strong>

            <span className="text-muted-foreground text-sm">
              {" | "}
              {t("pages.provider_collections.index.delivered_meals", {
                count: group.meals,
              })}
            </span>
          </p>

          <Progress value={progress} className="h-2" />
        </div>

        <ul className="grid gap-1 text-sm">
          <li className="flex items-center gap-2 text-green-700 dark:text-green-400">
            <CircleCheck className="size-4" aria-hidden="true" />
            {t("pages.provider_collections.group.confirmed", {
              amount: formatMoney(amountsByStatus.approved),
            })}
          </li>

          {amountsByStatus.pending > 0 && (
            <li className="flex items-center gap-2 text-amber-700 dark:text-amber-400">
              <TriangleAlert className="size-4" aria-hidden="true" />
              {t("pages.provider_collections.group.pending", {
                amount: formatMoney(amountsByStatus.pending),
              })}
            </li>
          )}

          {amountsByStatus.submitted > 0 && (
            <li className="flex items-center gap-2 text-sky-700 dark:text-sky-400">
              <TriangleAlert className="size-4" aria-hidden="true" />
              {t("pages.provider_collections.group.submitted", {
                amount: formatMoney(amountsByStatus.submitted),
              })}
            </li>
          )}

          {amountsByStatus.rejected > 0 && (
            <li className="flex items-center gap-2 text-red-700 dark:text-red-400">
              <TriangleAlert className="size-4" aria-hidden="true" />
              {t("pages.provider_collections.group.rejected", {
                amount: formatMoney(amountsByStatus.rejected),
              })}
            </li>
          )}
        </ul>

        <div className="grid">
          {group.employees.length > 0 && (
            <>
              <Separator />

              <OwnerGroup
                icon={Users}
                title={t("pages.provider_collections.group.employees")}
                status={employeesStatus}
                amount={group.employees_total}
              >
                {group.employees.map((employee) => (
                  <Collapsible key={employee.id} className="rounded-lg border">
                    <CollapsibleTrigger className="group flex w-full items-center gap-3 px-3 py-2.5 text-left">
                      <span className="flex-1 text-sm">
                        {employee.owner_name}
                      </span>

                      {settled ? (
                        <span className="text-muted-foreground text-xs">
                          {employee.paid_on}
                        </span>
                      ) : (
                        <StatusBadge status={employee.status} kind="payment" />
                      )}

                      <Chevron />
                    </CollapsibleTrigger>

                    <CollapsibleContent className="px-3 pb-3">
                      <CollectionAccountPanel
                        account={employee}
                        heading={settled ? "none" : "month"}
                      />
                    </CollapsibleContent>
                  </Collapsible>
                ))}
              </OwnerGroup>
            </>
          )}

          {group.company && (
            <>
              <Separator />

              <OwnerGroup
                icon={Building2}
                title={t("pages.provider_collections.group.company")}
                status={group.company.status}
                amount={group.company.amount}
              >
                <CollectionAccountPanel
                  account={group.company}
                  heading={settled ? "paid_on" : "month"}
                />
              </OwnerGroup>
            </>
          )}
        </div>
      </CardContent>
    </Card>
  )
}
