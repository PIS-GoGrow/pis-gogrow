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
import { Textarea } from "@/components/ui/textarea"
import { providerDashboard, providerOnboarding } from "@/routes"
import type { ProviderOnboardingShow } from "@/types/serializers/ProviderOnboardingShow"

const TOTAL_STEPS = 4
const PAGE = "pages.provider_onboarding"
const PRIMARY_BUTTON = "h-12 w-full rounded-[10px] text-base font-medium"
const SECONDARY_BUTTON = "h-12 w-full text-base font-medium"

const REQUIRED_STEP_1_FIELDS = [
  "provider[bank_name]",
  "provider[bank_account_details]",
  "provider[beneficiary]",
] as const

function step1Complete(provider: ProviderOnboardingShow["provider"]) {
  return [
    provider.bank_name,
    provider.bank_account_details,
    provider.beneficiary,
  ].every((value) => (value ?? "").toString().trim() !== "")
}

export default function Onboarding({
  provider,
  bank_names,
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
  const [skippingIntro, setSkippingIntro] = useState(false)

  if (step === "intro") {
    function skipIntro() {
      setSkippingIntro(true)
      router.patch(
        providerOnboarding.update().url,
        { step: "intro", commit: "skip" },
        {
          preserveScroll: true,
          onFinish: () => setSkippingIntro(false),
        },
      )
    }

    return (
      <Shell>
        <Head title={t(`${PAGE}.intro.title`)} />
        <div className="flex flex-1 flex-col items-center justify-center text-center">
          <ProviderAvatar name={provider.name} />
          <h1 className="text-2xl font-bold tracking-tight text-[#0A0A0A] dark:text-neutral-100">
            {t(`${PAGE}.intro.title`)}
          </h1>
          <p className="text-muted-foreground mt-3 max-w-xs text-sm leading-relaxed">
            {t(`${PAGE}.intro.description`)}
          </p>
        </div>
        <div className="flex flex-col gap-2">
          <Button asChild size="lg" className={PRIMARY_BUTTON}>
            <Link href={`${providerOnboarding.show().url}?step=1`}>
              {t(`${PAGE}.intro.start`)}
            </Link>
          </Button>
          <Button
            type="button"
            variant="ghost"
            size="lg"
            disabled={skippingIntro}
            onClick={skipIntro}
            className={SECONDARY_BUTTON}
          >
            {t(`${PAGE}.intro.skip_later`)}
          </Button>
        </div>
      </Shell>
    )
  }

  if (step === "done") {
    return (
      <Shell>
        <Head title={t(`${PAGE}.done.title`)} />
        <div className="flex flex-1 flex-col items-center justify-center text-center">
          <ProviderAvatar name={provider.name} />
          <h1 className="text-2xl font-bold tracking-tight text-[#0A0A0A] dark:text-neutral-100">
            {t(`${PAGE}.done.title`)}
          </h1>
          <p className="text-muted-foreground mt-3 max-w-xs text-sm leading-relaxed">
            {t(`${PAGE}.done.description`)}
          </p>
        </div>
        <Button asChild size="lg" className={PRIMARY_BUTTON}>
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
          noValidate
        >
          {({ errors, processing }) => (
            <>
              <input type="hidden" name="step" value={current} />
              <div className="flex-1" onChange={handleStep1Change}>
                <PaymentDetailsFields
                  provider={provider}
                  bankNames={bank_names}
                  errors={errors}
                />
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

function ProviderAvatar({ name }: { name: string }) {
  const { t } = useTranslation()

  return (
    <div className="mb-6 flex size-24 items-center justify-center rounded-full bg-[#0A0A0A] p-3 text-center text-base font-semibold text-[#FAFAFA]">
      {name || t("roles.provider")}
    </div>
  )
}

function Shell({ children }: { children: React.ReactNode }) {
  return (
    <div className="bg-background flex min-h-svh justify-center p-6">
      <div className="flex w-full max-w-300 flex-col gap-6">{children}</div>
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
        {current < TOTAL_STEPS && (
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
        )}
      </div>
    </div>
  )
}

function StepIntro({ step }: { step: number }) {
  const { t } = useTranslation()

  return (
    <div className="mb-6">
      <h1 className="text-2xl font-bold tracking-tight">
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
        size="lg"
        disabled={processing || !canContinue}
        className={PRIMARY_BUTTON}
      >
        {isLast ? t(`${PAGE}.finish`) : t(`${PAGE}.continue`)}
      </Button>
      {!isLast && (
        <Button
          type="button"
          variant="ghost"
          size="lg"
          disabled={processing}
          onClick={onSkip}
          className={SECONDARY_BUTTON}
        >
          {t(`${PAGE}.skip`)}
        </Button>
      )}
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
  onSkip?: () => void
  canContinue?: boolean
}) {
  const { t } = useTranslation()

  return (
    <div className="flex flex-col gap-2">
      <Button
        type="button"
        disabled={processing || !canContinue}
        onClick={onContinue}
        className={PRIMARY_BUTTON}
      >
        {isLast ? t(`${PAGE}.finish`) : t(`${PAGE}.continue`)}
      </Button>
      {!isLast && onSkip && (
        <Button
          type="button"
          variant="ghost"
          size="lg"
          disabled={processing}
          onClick={onSkip}
          className={SECONDARY_BUTTON}
        >
          {t(`${PAGE}.skip`)}
        </Button>
      )}
    </div>
  )
}

function PaymentDetailsFields({
  provider,
  bankNames,
  errors,
}: {
  provider: ProviderOnboardingShow["provider"]
  bankNames: ProviderOnboardingShow["bank_names"]
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
          <Select
            name="provider[bank_name]"
            defaultValue={provider.bank_name ?? undefined}
          >
            <SelectTrigger
              id="bank_name"
              className="w-full"
              aria-invalid={!!errors.bank_name}
            >
              <SelectValue placeholder={t(`${fields}.bank_name_placeholder`)} />
            </SelectTrigger>
            <SelectContent>
              {bankNames.map((bankName) => (
                <SelectItem key={bankName} value={bankName}>
                  {bankName}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <FieldError>{errors.bank_name}</FieldError>
        </Field>

        <Field data-invalid={!!errors.bank_account_details}>
          <FieldLabel htmlFor="bank_account_details">
            {t(`${fields}.bank_account_details`)}
          </FieldLabel>
          <Textarea
            id="bank_account_details"
            name="provider[bank_account_details]"
            defaultValue={provider.bank_account_details ?? ""}
            placeholder={t(`${fields}.bank_account_details_placeholder`)}
            className="min-h-36"
            aria-invalid={!!errors.bank_account_details}
          />
          <FieldError>{errors.bank_account_details}</FieldError>
        </Field>

        <Field data-invalid={!!errors.beneficiary}>
          <FieldLabel htmlFor="beneficiary">
            {t(`${fields}.beneficiary`)}
          </FieldLabel>
          <Input
            id="beneficiary"
            name="provider[beneficiary]"
            defaultValue={provider.beneficiary ?? ""}
            aria-invalid={!!errors.beneficiary}
          />
          <FieldError>{errors.beneficiary}</FieldError>
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
