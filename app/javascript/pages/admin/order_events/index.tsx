import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft, History } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { DateRangePicker } from "@/components/date-picker"
import PageContainer from "@/components/page-container"
import { Button } from "@/components/ui/button"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import { Field, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import AppLayout from "@/layouts/app-layout"
import { adminAccount, adminOrderEvents } from "@/routes"
import type {
  AdminOrderEventsIndex,
  BreadcrumbItem,
  OrderEventAction,
  OrderEventRole,
} from "@/types"

const actions: OrderEventAction[] = [
  "created",
  "modified",
  "price_changed",
  "confirmed",
  "cancelled",
  "rejected",
]
const roles: OrderEventRole[] = ["consumer", "provider", "admin"]

export default function Index({
  events,
  total,
  filters,
}: AdminOrderEventsIndex) {
  const { t } = useTranslation()
  const page = "pages.admin.order_events.index"
  const [from, setFrom] = useState(filters.from ?? "")
  const [to, setTo] = useState(filters.to ?? "")

  const breadcrumbs: BreadcrumbItem[] = [
    { title: t("nav.order_events"), href: adminOrderEvents.index().url },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t(`${page}.title`)} />

      <PageContainer
        title={t(`${page}.title`)}
        description={t(`${page}.description`)}
        back={
          <Button variant="ghost" size="icon" asChild>
            <Link href={adminAccount().url} aria-label={t(`${page}.back`)}>
              <ArrowLeft aria-hidden="true" />
            </Link>
          </Button>
        }
      >
        <Form
          action={adminOrderEvents.index()}
          options={{ preserveScroll: true }}
          className="grid items-end gap-4 sm:grid-cols-2 lg:grid-cols-6"
        >
          <Field>
            <FieldLabel htmlFor="order_id">
              {t(`${page}.filters.order`)}
            </FieldLabel>
            <Input
              id="order_id"
              name="order_id"
              defaultValue={filters.order_id}
              placeholder={t(`${page}.filters.order_placeholder`)}
            />
          </Field>

          <Field>
            <FieldLabel htmlFor="event_action">
              {t(`${page}.filters.action`)}
            </FieldLabel>
            <Select
              name="event_action"
              defaultValue={filters.event_action ?? "all"}
            >
              <SelectTrigger id="event_action" className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">{t(`${page}.filters.all`)}</SelectItem>
                {actions.map((action) => (
                  <SelectItem key={action} value={action}>
                    {t(`${page}.actions.${action}`)}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>

          <Field>
            <FieldLabel htmlFor="role">{t(`${page}.filters.role`)}</FieldLabel>
            <Select name="role" defaultValue={filters.role ?? "all"}>
              <SelectTrigger id="role" className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">
                  {t(`${page}.filters.all_roles`)}
                </SelectItem>
                {roles.map((role) => (
                  <SelectItem key={role} value={role}>
                    {t(`${page}.roles.${role}`)}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </Field>

          <Field>
            <FieldLabel htmlFor="actor">
              {t(`${page}.filters.actor`)}
            </FieldLabel>
            <Input
              id="actor"
              name="actor"
              defaultValue={filters.actor}
              placeholder={t(`${page}.filters.actor_placeholder`)}
            />
          </Field>

          <Field>
            <FieldLabel htmlFor="dates">
              {t(`${page}.filters.dates`)}
            </FieldLabel>
            <DateRangePicker
              id="dates"
              from={from}
              to={to}
              onChange={(newFrom, newTo) => {
                setFrom(newFrom)
                setTo(newTo)
              }}
            />
            <input type="hidden" name="from" value={from} />
            <input type="hidden" name="to" value={to} />
          </Field>

          <div className="flex gap-2">
            <Button type="submit">{t(`${page}.filters.apply`)}</Button>
            <Button variant="ghost" asChild>
              <Link href={adminOrderEvents.index().url}>
                {t(`${page}.filters.clear`)}
              </Link>
            </Button>
          </div>
        </Form>

        {events.length === 0 ? (
          <Empty className="border">
            <EmptyHeader>
              <EmptyMedia variant="icon">
                <History aria-hidden="true" />
              </EmptyMedia>
              <EmptyTitle>{t(`${page}.empty_title`)}</EmptyTitle>
              <EmptyDescription>
                {t(`${page}.empty_description`)}
              </EmptyDescription>
            </EmptyHeader>
          </Empty>
        ) : (
          <>
            {total > events.length && (
              <p className="text-muted-foreground text-sm">
                {t(`${page}.truncated`, { shown: events.length, total })}
              </p>
            )}
            <div className="overflow-x-auto rounded-md border">
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>{t(`${page}.occurred_at`)}</TableHead>
                    <TableHead>{t(`${page}.order`)}</TableHead>
                    <TableHead>{t(`${page}.actor`)}</TableHead>
                    <TableHead>{t(`${page}.role`)}</TableHead>
                    <TableHead>{t(`${page}.action`)}</TableHead>
                    <TableHead>{t(`${page}.changes`)}</TableHead>
                    <TableHead>{t(`${page}.before`)}</TableHead>
                    <TableHead>{t(`${page}.after`)}</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {events.map((event) =>
                    event.changes.map((change, index) => (
                      <TableRow key={`${event.id}-${change.field}`}>
                        {index === 0 && (
                          <>
                            <TableCell
                              rowSpan={event.changes.length}
                              className="align-top whitespace-nowrap"
                            >
                              {event.occurred_at}
                            </TableCell>
                            <TableCell
                              rowSpan={event.changes.length}
                              className="align-top"
                            >
                              <div className="font-medium whitespace-nowrap">
                                {t("pages.provider_orders.index.code", {
                                  id: event.order_id,
                                })}
                              </div>
                              <div className="text-muted-foreground text-xs">
                                {[event.consumer_name, event.dish]
                                  .filter(Boolean)
                                  .join(" · ")}
                              </div>
                            </TableCell>
                            <TableCell
                              rowSpan={event.changes.length}
                              className="align-top"
                            >
                              {event.actor_name ?? t(`${page}.system`)}
                            </TableCell>
                            <TableCell
                              rowSpan={event.changes.length}
                              className="align-top"
                            >
                              {event.role
                                ? t(`${page}.roles.${event.role}`)
                                : t(`${page}.empty_value`)}
                            </TableCell>
                            <TableCell
                              rowSpan={event.changes.length}
                              className="align-top"
                            >
                              {t(`${page}.actions.${event.action}`)}
                            </TableCell>
                          </>
                        )}
                        <TableCell>
                          {t(`${page}.fields.${change.field}`)}
                        </TableCell>
                        <TableCell className="text-muted-foreground">
                          {change.before ?? t(`${page}.empty_value`)}
                        </TableCell>
                        <TableCell>
                          {change.after ?? t(`${page}.empty_value`)}
                        </TableCell>
                      </TableRow>
                    )),
                  )}
                </TableBody>
              </Table>
            </div>
          </>
        )}
      </PageContainer>
    </AppLayout>
  )
}
