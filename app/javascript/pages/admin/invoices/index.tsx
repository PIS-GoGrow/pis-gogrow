import { Head } from "@inertiajs/react"
import { Download, FileText } from "lucide-react"
import { useTranslation } from "react-i18next"

import PageContainer from "@/components/page-container"
import StatusBadge from "@/components/status-badge"
import { Button } from "@/components/ui/button"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { useFormatters } from "@/hooks/use-formatters"
import AppLayout from "@/layouts/app-layout"
import { adminInvoices } from "@/routes"
import type { AdminInvoicesIndex, BreadcrumbItem } from "@/types"

export default function Index({ invoices }: AdminInvoicesIndex) {
  const { t } = useTranslation()
  const { formatMoney } = useFormatters()

  const breadcrumbs: BreadcrumbItem[] = [
    { title: t("nav.invoices"), href: adminInvoices.index().url },
  ]

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.admin.invoices.index.title")} />

      <PageContainer
        title={t("pages.admin.invoices.index.title")}
        description={t("pages.admin.invoices.index.description")}
      >
        {invoices.length === 0 ? (
          <Empty className="border">
            <EmptyHeader>
              <EmptyMedia variant="icon">
                <FileText aria-hidden="true" />
              </EmptyMedia>
              <EmptyTitle>
                {t("pages.admin.invoices.index.empty_title")}
              </EmptyTitle>
              <EmptyDescription>
                {t("pages.admin.invoices.index.empty_description")}
              </EmptyDescription>
            </EmptyHeader>
          </Empty>
        ) : (
          <div className="overflow-x-auto rounded-md border">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>
                    {t("pages.admin.invoices.index.period")}
                  </TableHead>
                  <TableHead>
                    {t("pages.admin.invoices.index.provider")}
                  </TableHead>
                  <TableHead>
                    {t("pages.admin.invoices.index.issued_on")}
                  </TableHead>
                  <TableHead className="text-right">
                    {t("pages.admin.invoices.index.total_amount")}
                  </TableHead>
                  <TableHead className="text-right">
                    {t("pages.admin.invoices.index.period_amount")}
                  </TableHead>
                  <TableHead>
                    {t("pages.admin.invoices.index.status")}
                  </TableHead>
                  <TableHead className="text-right">
                    {t("pages.admin.invoices.index.file")}
                  </TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {invoices.map((invoice) => (
                  <TableRow key={invoice.id}>
                    <TableCell className="capitalize">
                      {invoice.period}
                    </TableCell>
                    <TableCell>{invoice.provider_name}</TableCell>
                    <TableCell>{invoice.issued_on}</TableCell>
                    <TableCell className="text-right font-medium">
                      {formatMoney(invoice.total_amount)}
                    </TableCell>
                    <TableCell className="text-muted-foreground text-right">
                      {invoice.period_amount == null
                        ? t("pages.admin.invoices.index.no_period_amount")
                        : formatMoney(invoice.period_amount)}
                    </TableCell>
                    <TableCell>
                      <StatusBadge status={invoice.status} kind="invoice" />
                    </TableCell>
                    <TableCell>
                      <div className="flex items-center justify-end gap-1">
                        {/* Enlaces y no visitas de Inertia: el servidor
                            responde el archivo, no una página. */}
                        <Button variant="ghost" size="sm" asChild>
                          <a
                            href={adminInvoices.file(invoice.id).url}
                            target="_blank"
                            rel="noreferrer"
                          >
                            {t("pages.admin.invoices.index.view")}
                          </a>
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          aria-label={t("pages.admin.invoices.index.download", {
                            name: invoice.file_name,
                          })}
                          asChild
                        >
                          <a
                            href={
                              adminInvoices.file(invoice.id, {
                                query: { download: 1 },
                              }).url
                            }
                          >
                            <Download aria-hidden="true" />
                          </a>
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </div>
        )}
      </PageContainer>
    </AppLayout>
  )
}
