import { Form, Head, Link } from "@inertiajs/react"
import { ArrowLeft } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

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
  const { formatDeliveryDate } = useFormatters()
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
    order.date && formatDeliveryDate(order.date),
  ]
    .filter(Boolean)
    .join(" · ")

  return (
    <AppLayout breadcrumbs={breadcrumbs}>
      <Head title={t("pages.reviews.new.title")} />

      <div className="mx-auto grid w-full max-w-128 gap-6 p-5">
        <Button
          variant="ghost"
          size="sm"
          className="justify-self-start"
          asChild
        >
          <Link href={consumerOrders.index().url}>
            <ArrowLeft />
            {t("pages.reviews.new.back")}
          </Link>
        </Button>

        <h1 className="text-2xl font-bold">{t("pages.reviews.new.title")}</h1>

        <Card>
          <CardHeader>
            {subtitle && <CardDescription>{subtitle}</CardDescription>}
            <CardTitle className="text-lg">
              {order.menu_name ?? t("pages.orders.index.no_menu")}
            </CardTitle>
          </CardHeader>
        </Card>

        <Form action={consumerReviews.create(order.id)} className="grid gap-6">
          {({ processing, errors }) => (
            <>
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
                  maxLength={MAX_DESCRIPTION}
                  rows={4}
                  placeholder={t("pages.reviews.new.placeholder")}
                  value={description}
                  onChange={(event) => setDescription(event.target.value)}
                  aria-invalid={!!errors.description}
                />
                <p className="text-muted-foreground justify-self-end text-xs">
                  {t("pages.reviews.new.counter", {
                    count: description.length,
                  })}
                </p>
                <FieldError
                  errors={errors.description?.map((message) => ({ message }))}
                />
              </Field>

              <Button
                type="submit"
                size="lg"
                className="w-full"
                disabled={rating === 0 || processing}
              >
                {processing && <Spinner />}
                {t("pages.reviews.new.submit")}
              </Button>
            </>
          )}
        </Form>
      </div>
    </AppLayout>
  )
}
