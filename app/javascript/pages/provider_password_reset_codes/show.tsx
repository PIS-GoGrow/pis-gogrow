import { Form, Head, router } from "@inertiajs/react"
import { REGEXP_ONLY_DIGITS } from "input-otp"
import { useEffect, useState } from "react"
import { useTranslation } from "react-i18next"

import TextLink from "@/components/text-link"
import { Button } from "@/components/ui/button"
import { Field, FieldError } from "@/components/ui/field"
import {
  InputOTP,
  InputOTPGroup,
  InputOTPSlot,
} from "@/components/ui/input-otp"
import { Spinner } from "@/components/ui/spinner"
import AuthLayout from "@/layouts/auth-layout"
import {
  providerPasswordResetCodes,
  providerPasswordResets,
  providerSessions,
} from "@/routes"
import type { ProviderPasswordResetCodesShow } from "@/types"

const CODE_LENGTH = 6

function formatTime(seconds: number) {
  return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`
}

function ResendButton({ email, seconds }: { email: string; seconds: number }) {
  const { t } = useTranslation()
  const [left, setLeft] = useState(seconds)

  useEffect(() => {
    if (left <= 0) return
    const timer = setTimeout(() => setLeft((value) => value - 1), 1000)
    return () => clearTimeout(timer)
  }, [left])

  return (
    <Button
      type="button"
      variant="secondary"
      size="lg"
      className="w-full"
      disabled={left > 0}
      onClick={() => router.post(providerPasswordResets.create(), { email })}
    >
      {left > 0
        ? t("pages.provider_password_reset_codes.show.resend_in", {
            time: formatTime(left),
          })
        : t("pages.provider_password_reset_codes.show.resend")}
    </Button>
  )
}

export default function ProviderPasswordResetCode({
  email,
  resend_in,
}: ProviderPasswordResetCodesShow) {
  const { t } = useTranslation()
  const [code, setCode] = useState("")

  return (
    <AuthLayout
      title={t("pages.provider_password_reset_codes.show.title")}
      description={t("pages.provider_password_reset_codes.show.description", {
        email,
      })}
    >
      <Head title={t("pages.provider_password_reset_codes.show.title")} />

      <Form
        action={providerPasswordResetCodes.create()}
        className="flex flex-col gap-6"
      >
        {({ processing, errors }) => (
          <>
            <Field data-invalid={!!errors.code} className="items-center">
              <InputOTP
                name="code"
                maxLength={CODE_LENGTH}
                pattern={REGEXP_ONLY_DIGITS}
                autoFocus
                pushPasswordManagerStrategy="none"
                value={code}
                onChange={setCode}
                aria-invalid={!!errors.code}
              >
                <InputOTPGroup>
                  {Array.from({ length: CODE_LENGTH }, (_, index) => (
                    <InputOTPSlot
                      key={index}
                      index={index}
                      aria-invalid={!!errors.code}
                    />
                  ))}
                </InputOTPGroup>
              </InputOTP>
              <FieldError
                errors={errors.code?.map((message) => ({ message }))}
              />
            </Field>

            <Button
              type="submit"
              size="lg"
              className="w-full"
              disabled={code.length < CODE_LENGTH || processing}
            >
              {processing && <Spinner />}
              {t("pages.provider_password_reset_codes.show.submit")}
            </Button>
          </>
        )}
      </Form>

      <ResendButton key={resend_in} email={email} seconds={resend_in} />

      <div className="text-center text-sm">
        <TextLink href={providerSessions.new()}>
          {t("pages.provider_password_reset_codes.show.back")}
        </TextLink>
      </div>
    </AuthLayout>
  )
}
