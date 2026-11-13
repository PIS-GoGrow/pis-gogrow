import { Form, Head, Link } from "@inertiajs/react"
import { ChevronLeft } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import ReviewActions from "@/components/reviews/review-actions"
import ReviewPage from "@/components/reviews/review-page"
import StarRating from "@/components/reviews/star-rating"
import { Button } from "@/components/ui/button"
import {
  Card,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import { Field, FieldError, FieldLabel } from "@/components/ui/field"
import { Spinner } from "@/components/ui/spinner"
import { Textarea } from "@/components/ui/textarea"
import { useFormatters } from "@/hooks/use-formatters"
import AppLayout from "@/layouts/app-layout"
import { consumerOrders, consumerReviews } from "@/routes"
import type { BreadcrumbItem, ConsumerReviewsNew } from "@/types"

const MAX_DESCRIPTION = 200

export default function New({ order }: ConsumerReviewsNew) {
  const { t } = useTranslation()
  const { formatLongDate } = useFormatters()
  const [rating, setRating] = useState(0)
  const [description, setDescription] = useState("")

  const breadcrumbs: BreadcrumbItem[] = [
    {
      title: t("pages.orders.index.title"),
      href: consumerOrders.index().url,
    },
    {
      title: t("pages.reviews.new.title"),
      href: consumerReviews.new(order.id).url,
    },
  ]

  const subtitle = [
    order.provider_name,
    order.date && formatLongDate(order.date),
  ]
    .filter(Boolean)
    .join(" · ")

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.reviews.new.title")} />

      <ReviewPage>
        <Form
          action={consumerReviews.create(order.id)}
          className="flex min-h-0 flex-1 flex-col"
        >
          {({ processing, errors }) => (
            <>
              <div className="min-h-0 flex-1 overflow-y-auto px-5 pt-5">
                <div className="grid min-w-0 gap-6 pb-4">
                  <div className="relative flex min-h-11 items-center justify-center px-11">
                    <Button
                      variant="ghost"
                      size="icon"
                      className="absolute left-0 size-11"
                      asChild
                    >
                      <Link
                        href={consumerOrders.index().url}
                        aria-label={t("pages.reviews.new.back")}
                      >
                        <ChevronLeft aria-hidden="true" />
                      </Link>
                    </Button>
                    <h1 className="text-center text-base font-semibold">
                      {t("pages.reviews.new.title")}
                    </h1>
                  </div>

                  <Card className="bg-muted/40 gap-0 rounded-lg py-3 shadow-none">
                    <CardHeader className="gap-1 px-4">
                      <CardTitle className="text-sm font-semibold">
                        {order.menu_name ?? t("pages.orders.index.no_menu")}
                      </CardTitle>
                      {subtitle && (
                        <CardDescription className="text-xs">
                          {subtitle}
                        </CardDescription>
                      )}
                    </CardHeader>
                  </Card>

                  <input type="hidden" name="rating" value={rating || ""} />

                  <Field data-invalid={!!errors.rating}>
                    <FieldLabel>{t("pages.reviews.new.question")}</FieldLabel>
                    <StarRating value={rating} onChange={setRating} />
                    <FieldError
                      errors={errors.rating?.map((message) => ({ message }))}
                    />
                  </Field>

                  <Field data-invalid={!!errors.description}>
                    <FieldLabel htmlFor="description">
                      {t("pages.reviews.new.experience")}
                    </FieldLabel>
                    <Textarea
                      id="description"
                      name="description"
                      className="field-sizing-fixed min-h-28 min-w-0 resize-y overflow-x-hidden [overflow-wrap:anywhere] whitespace-pre-wrap"
                      wrap="soft"
                      maxLength={MAX_DESCRIPTION}
                      rows={4}
                      placeholder={t("pages.reviews.new.placeholder")}
                      value={description}
                      onChange={(event) => setDescription(event.target.value)}
                      aria-invalid={!!errors.description}
                    />
                    <p className="text-muted-foreground w-full text-right text-xs">
                      {t("pages.reviews.new.counter", {
                        count: description.length,
                      })}
                    </p>
                    <FieldError
                      errors={errors.description?.map((message) => ({
                        message,
                      }))}
                    />
                  </Field>
                </div>
              </div>
              <ReviewActions>
                <Button
                  type="submit"
                  size="lg"
                  className="w-full"
                  disabled={rating === 0 || processing}
                >
                  {processing && <Spinner />}
                  {t("pages.reviews.new.submit")}
                </Button>
              </ReviewActions>
            </>
          )}
        </Form>
      </ReviewPage>
    </AppLayout>
  )
}
