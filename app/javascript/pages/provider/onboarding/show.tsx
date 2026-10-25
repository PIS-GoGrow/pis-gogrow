import type { ErrorValue } from "@inertiajs/core"
import { Form, Head, Link, router } from "@inertiajs/react"
import { ChevronLeft, ChevronRight } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import ClosingTimeSection from "@/components/provider/closing-time-section"
import ClosuresSection from "@/components/provider/closures-section"
import { Button } from "@/components/ui/button"
import {
  Field,
  FieldContent,
  FieldDescription,
  FieldError,
  FieldGroup,
  FieldLabel,
  FieldTitle,
} from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group"
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select"
import { Switch } from "@/components/ui/switch"
import { providerDashboard, providerOnboarding } from "@/routes"
import type { ProviderOnboardingShow } from "@/types/serializers/ProviderOnboardingShow"

const TOTAL_STEPS = 4
const PAGE = "pages.provider_onboarding"

const REQUIRED_STEP_1_FIELDS = [
  "provider[bank_name]",
  "provider[bank_account_type]",
  "provider[bank_account_number]",
  "provider[bank_account_holder]",
  "provider[tax_id]",
] as const

function step1Complete(provider: ProviderOnboardingShow["provider"]) {
  return [
    provider.bank_name,
    provider.bank_account_type,
    provider.bank_account_number,
    provider.bank_account_holder,
    provider.tax_id,
  ].every((value) => (value ?? "").toString().trim() !== "")
}

export default function Onboarding({
  provider,
  step,
  notification_configurations,
  subscribed_keys,
  closures,
  today,
  order_deadline_passed_today,
}: ProviderOnboardingShow) {
  const { t } = useTranslation()
  const [canContinue, setCanContinue] = useState(() =>
    step === "1" ? step1Complete(provider) : true,
  )

  if (step === "done") {
    return (
      <Shell>
        <Head title={t(`${PAGE}.done.title`)} />
        <div className="flex flex-1 flex-col items-center justify-center text-center">
          <h1 className="text-2xl font-semibold">{t(`${PAGE}.done.title`)}</h1>
          <p className="text-muted-foreground mt-3 max-w-xs">
            {t(`${PAGE}.done.description`)}
          </p>
        </div>
        <Button asChild className="w-full">
          <Link href={providerDashboard.index()}>{t(`${PAGE}.done.cta`)}</Link>
        </Button>
      </Shell>
    )
  }

  const current = Number(step)

  function handleStep1Change(event: React.FormEvent<HTMLDivElement>) {
    if (current !== 1) return

    const form = event.currentTarget.closest("form")
    if (!form) return

    const data = new FormData(form)
    setCanContinue(
      REQUIRED_STEP_1_FIELDS.every((name) => {
        const value = data.get(name)
        return typeof value === "string" && value.trim() !== ""
      }),
    )
  }

  function skip() {
    router.patch(
      providerOnboarding.update().url,
      { step: current, commit: "skip" },
      { preserveScroll: true },
    )
  }

  function back() {
    router.get(
      providerOnboarding.show().url,
      { step: current - 1 },
      { preserveScroll: true },
    )
  }

  return (
    <Shell>
      <Head title={t(`${PAGE}.steps.${current}.title`)} />
      <StepHeader current={current} onBack={back} onSkip={skip} />

      {current === 4 ? (
        <NotificationsStep
          configurations={notification_configurations}
          subscribedKeys={subscribed_keys}
          onSkip={skip}
        />
      ) : current === 3 ? (
        <DeliveriesStep
          homeDelivery={provider.home_delivery}
          configured={provider.deliveries_configured}
          onSkip={skip}
        />
      ) : current === 2 ? (
        <OrderConfigStep
          provider={provider}
          closures={closures}
          today={today}
          orderDeadlinePassedToday={order_deadline_passed_today}
          onSkip={skip}
        />
      ) : (
        <Form
          action={providerOnboarding.update()}
          options={{ preserveScroll: true }}
          className="flex flex-1 flex-col"
        >
          {({ errors, processing }) => (
            <>
              <input type="hidden" name="step" value={current} />
              <div className="flex-1" onChange={handleStep1Change}>
                <PaymentDetailsFields provider={provider} errors={errors} />
              </div>
              <Footer
                processing={processing}
                isLast={false}
                canContinue={canContinue}
                onSkip={skip}
              />
            </>
          )}
        </Form>
      )}
    </Shell>
  )
}

function Shell({ children }: { children: React.ReactNode }) {
  return (
    <div className="bg-background flex min-h-svh justify-center p-6">
      <div className="flex w-full max-w-md flex-col gap-6">{children}</div>
    </div>
  )
}

function StepHeader({
  current,
  onBack,
  onSkip,
}: {
  current: number
  onBack: () => void
  onSkip: () => void
}) {
  const { t } = useTranslation()

  return (
    <div className="flex items-center justify-between">
      <div className="flex flex-1 justify-start">
        {current > 1 && (
          <Button
            type="button"
            variant="outline"
            size="icon"
            className="rounded-full"
            aria-label={t(`${PAGE}.back`)}
            onClick={onBack}
          >
            <ChevronLeft aria-hidden="true" />
          </Button>
        )}
      </div>
      <span className="text-sm font-medium">
        {t(`${PAGE}.progress`, { current, total: TOTAL_STEPS })}
      </span>
      <div className="flex flex-1 justify-end">
        <Button
          type="button"
          variant="outline"
          size="icon"
          className="rounded-full"
          aria-label={t(`${PAGE}.skip`)}
          onClick={onSkip}
        >
          <ChevronRight aria-hidden="true" />
        </Button>
      </div>
    </div>
  )
}

function StepIntro({ step }: { step: number }) {
  const { t } = useTranslation()

  return (
    <div className="mb-6">
      <h1 className="text-2xl font-semibold">
        {t(`${PAGE}.steps.${step}.title`)}
      </h1>
      <p className="text-muted-foreground mt-2">
        {t(`${PAGE}.steps.${step}.description`)}
      </p>
    </div>
  )
}

function Footer({
  processing,
  isLast,
  canContinue,
  onSkip,
}: {
  processing: boolean
  isLast: boolean
  canContinue: boolean
  onSkip: () => void
}) {
  const { t } = useTranslation()

  return (
    <div className="flex flex-col gap-2">
      <Button
        type="submit"
        name="commit"
        value="continue"
        disabled={processing || !canContinue}
        className="w-full"
      >
        {isLast ? t(`${PAGE}.finish`) : t(`${PAGE}.continue`)}
      </Button>
      <Button
        type="button"
        variant="ghost"
        disabled={processing}
        onClick={onSkip}
      >
        {t(`${PAGE}.skip`)}
      </Button>
    </div>
  )
}

function ControlledFooter({
  processing,
  isLast,
  onContinue,
  onSkip,
  canContinue = true,
}: {
  processing: boolean
  isLast: boolean
  onContinue: () => void
  onSkip: () => void
  canContinue?: boolean
}) {
  const { t } = useTranslation()

  return (
    <div className="flex flex-col gap-2">
      <Button
        type="button"
        disabled={processing || !canContinue}
        onClick={onContinue}
        className="w-full"
      >
        {isLast ? t(`${PAGE}.finish`) : t(`${PAGE}.continue`)}
      </Button>
      <Button
        type="button"
        variant="ghost"
        disabled={processing}
        onClick={onSkip}
      >
        {t(`${PAGE}.skip`)}
      </Button>
    </div>
  )
}

function PaymentDetailsFields({
  provider,
  errors,
}: {
  provider: ProviderOnboardingShow["provider"]
  errors: Record<string, ErrorValue>
}) {
  const { t } = useTranslation()
  const fields = "pages.provider_payment_details.show"

  return (
    <>
      <StepIntro step={1} />
      <FieldGroup>
        <Field data-invalid={!!errors.bank_name}>
          <FieldLabel htmlFor="bank_name">
            {t(`${fields}.bank_name`)}
          </FieldLabel>
          <Input
            id="bank_name"
            name="provider[bank_name]"
            defaultValue={provider.bank_name ?? ""}
            placeholder={t(`${fields}.bank_name_placeholder`)}
            aria-invalid={!!errors.bank_name}
          />
          <FieldError>{errors.bank_name}</FieldError>
        </Field>

        <Field data-invalid={!!errors.bank_account_type}>
          <FieldLabel htmlFor="bank_account_type">
            {t(`${fields}.bank_account_type`)}
          </FieldLabel>
          <Select
            name="provider[bank_account_type]"
            defaultValue={provider.bank_account_type ?? undefined}
          >
            <SelectTrigger
              id="bank_account_type"
              className="w-full"
              aria-invalid={!!errors.bank_account_type}
            >
              <SelectValue
                placeholder={t(`${fields}.bank_account_type_placeholder`)}
              />
            </SelectTrigger>
            <SelectContent>
              {(["savings", "checking"] as const).map((type) => (
                <SelectItem key={type} value={type}>
                  {t(`${fields}.bank_account_types.${type}`)}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <FieldError>{errors.bank_account_type}</FieldError>
        </Field>

        <Field data-invalid={!!errors.bank_account_number}>
          <FieldLabel htmlFor="bank_account_number">
            {t(`${fields}.bank_account_number`)}
          </FieldLabel>
          <Input
            id="bank_account_number"
            name="provider[bank_account_number]"
            inputMode="numeric"
            defaultValue={provider.bank_account_number ?? ""}
            aria-invalid={!!errors.bank_account_number}
          />
          <FieldError>{errors.bank_account_number}</FieldError>
        </Field>

        <Field data-invalid={!!errors.bank_account_holder}>
          <FieldLabel htmlFor="bank_account_holder">
            {t(`${fields}.bank_account_holder`)}
          </FieldLabel>
          <Input
            id="bank_account_holder"
            name="provider[bank_account_holder]"
            defaultValue={provider.bank_account_holder ?? ""}
            aria-invalid={!!errors.bank_account_holder}
          />
          <FieldError>{errors.bank_account_holder}</FieldError>
        </Field>

        <Field data-invalid={!!errors.tax_id}>
          <FieldLabel htmlFor="tax_id">{t(`${fields}.tax_id`)}</FieldLabel>
          <Input
            id="tax_id"
            name="provider[tax_id]"
            inputMode="numeric"
            defaultValue={provider.tax_id ?? ""}
            aria-invalid={!!errors.tax_id}
          />
          <FieldDescription>
            {t(`${fields}.tax_id_description`)}
          </FieldDescription>
          <FieldError>{errors.tax_id}</FieldError>
        </Field>
      </FieldGroup>
    </>
  )
}

function OrderConfigStep({
  provider,
  closures,
  today,
  orderDeadlinePassedToday,
  onSkip,
}: {
  provider: ProviderOnboardingShow["provider"]
  closures: ProviderOnboardingShow["closures"]
  today: string
  orderDeadlinePassedToday: boolean
  onSkip: () => void
}) {
  const [processing, setProcessing] = useState(false)

  function submit() {
    setProcessing(true)
    router.patch(
      providerOnboarding.update().url,
      { step: 2, commit: "continue" },
      { preserveScroll: true, onFinish: () => setProcessing(false) },
    )
  }

  return (
    <>
      <div className="flex-1">
        <StepIntro step={2} />
        <div className="flex flex-col gap-4">
          <ClosingTimeSection
            orderDeadline={provider.order_deadline}
            orderDeadlinePassedToday={orderDeadlinePassedToday}
            onboarding
          />
          <ClosuresSection closures={closures} today={today} onboarding />
        </div>
      </div>
      <ControlledFooter
        processing={processing}
        isLast={false}
        onContinue={submit}
        onSkip={onSkip}
        canContinue={!!provider.order_deadline}
      />
    </>
  )
}

function DeliveriesStep({
  homeDelivery,
  configured,
  onSkip,
}: {
  homeDelivery: boolean
  configured: boolean
  onSkip: () => void
}) {
  const { t } = useTranslation()
  const [selected, setSelected] = useState<"office" | "home" | null>(
    configured ? (homeDelivery ? "home" : "office") : null,
  )
  const [processing, setProcessing] = useState(false)
  const deliveries = "pages.provider_deliveries.show"

  function submit() {
    if (!selected) return

    setProcessing(true)
    router.patch(
      providerOnboarding.update().url,
      { step: 3, commit: "continue", home_delivery: selected === "home" },
      { preserveScroll: true, onFinish: () => setProcessing(false) },
    )
  }

  return (
    <>
      <div className="flex-1">
        <StepIntro step={3} />
        <RadioGroup
          value={selected ?? ""}
          onValueChange={(value) => setSelected(value as "office" | "home")}
          aria-label={t(`${PAGE}.steps.3.title`)}
          className="gap-3"
        >
          {(["office", "home"] as const).map((option) => (
            <FieldLabel key={option} htmlFor={`delivery-${option}`}>
              <Field orientation="horizontal">
                <RadioGroupItem value={option} id={`delivery-${option}`} />
                <FieldContent>
                  <FieldTitle>{t(`${deliveries}.${option}.title`)}</FieldTitle>
                  <FieldDescription>
                    {t(`${deliveries}.${option}.description`)}
                  </FieldDescription>
                </FieldContent>
              </Field>
            </FieldLabel>
          ))}
        </RadioGroup>
      </div>
      <ControlledFooter
        processing={processing}
        isLast={false}
        onContinue={submit}
        onSkip={onSkip}
        canContinue={selected !== null}
      />
    </>
  )
}

function NotificationsStep({
  configurations,
  subscribedKeys,
  onSkip,
}: {
  configurations: ProviderOnboardingShow["notification_configurations"]
  subscribedKeys: string[]
  onSkip: () => void
}) {
  const [subscribed, setSubscribed] = useState(() => new Set(subscribedKeys))
  const [processing, setProcessing] = useState(false)

  function toggle(key: string, on: boolean) {
    setSubscribed((prev) => {
      const next = new Set(prev)
      if (on) {
        next.add(key)
      } else {
        next.delete(key)
      }
      return next
    })
  }

  function submit() {
    setProcessing(true)
    const subscribedIds = configurations
      .filter(({ key }) => subscribed.has(key))
      .map(({ id }) => id)
    router.patch(
      providerOnboarding.update().url,
      { step: 4, commit: "continue", subscribed_ids: subscribedIds },
      { preserveScroll: true, onFinish: () => setProcessing(false) },
    )
  }

  return (
    <>
      <div className="flex-1">
        <StepIntro step={4} />
        <div className="grid gap-2">
          {configurations.map(({ id, key, title, description }) => (
            <div key={id} className="flex border-b py-3">
              <div className="min-w-0 flex-1 pr-5">
                <p className="font-medium">{title}</p>
                <p className="text-muted-foreground text-sm">{description}</p>
              </div>
              <Switch
                checked={subscribed.has(key)}
                onCheckedChange={(on) => toggle(key, on)}
              />
            </div>
          ))}
        </div>
      </div>
      <ControlledFooter
        processing={processing}
        isLast
        onContinue={submit}
        onSkip={onSkip}
      />
    </>
  )
}
