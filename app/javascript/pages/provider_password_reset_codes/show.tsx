import { Form, Head, router } from "@inertiajs/react"
import { REGEXP_ONLY_DIGITS } from "input-otp"
import { useEffect, useState } from "react"
import { useTranslation } from "react-i18next"

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
      size="lg"
      className="h-12 w-full rounded-[10px] bg-[#F4F4F5] text-sm font-medium text-[#737373] hover:bg-[#E4E4E7] disabled:opacity-80 dark:bg-neutral-800 dark:text-neutral-400 dark:hover:bg-neutral-700"
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
      backHref={providerSessions.new().url}
      variant="form"
    >
      <Head title={t("pages.provider_password_reset_codes.show.title")} />

      <Form
        action={providerPasswordResetCodes.create()}
        className="flex flex-1 flex-col justify-between gap-6"
      >
        {({ processing, errors }) => (
          <>
            <div className="flex w-full flex-col items-center justify-center">
              <Field data-invalid={!!errors.code} className="w-auto items-center">
                <InputOTP
                  name="code"
                  maxLength={CODE_LENGTH}
                  pattern={REGEXP_ONLY_DIGITS}
                  autoFocus
                  pushPasswordManagerStrategy="none"
                  value={code}
                  onChange={setCode}
                  aria-invalid={!!errors.code}
                  containerClassName="justify-center"
                >
                  <InputOTPGroup className="justify-center">
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
                  className="text-center"
                />
              </Field>
            </div>

            <div className="mt-auto flex flex-col gap-3 pt-6">
              <Button
                type="submit"
                size="lg"
                className="h-12 w-full rounded-[10px] bg-[#171717] text-base font-medium text-[#FAFAFA] hover:bg-[#171717]/90 disabled:opacity-50 dark:bg-white dark:text-black dark:hover:bg-white/90"
                disabled={code.length < CODE_LENGTH || processing}
              >
                {processing && <Spinner />}
                {t("pages.provider_password_reset_codes.show.submit")}
              </Button>

              <ResendButton key={resend_in} email={email} seconds={resend_in} />
            </div>
          </>
        )}
      </Form>
    </AuthLayout>
  )
}
