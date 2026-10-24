import { Form } from "@inertiajs/react"
import { useRef } from "react"
import { useTranslation } from "react-i18next"

import {
  AdaptableDialog,
  AdaptableDialogClose,
  AdaptableDialogContent,
  AdaptableDialogDescription,
  AdaptableDialogFooter,
  AdaptableDialogTitle,
  AdaptableDialogTrigger,
} from "@/components/adaptable-dialog"
import HeadingSmall from "@/components/heading-small"
import { Button } from "@/components/ui/button"
import { Field, FieldError, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { users } from "@/routes"

export default function DeleteUser() {
  const { t } = useTranslation()
  const passwordInput = useRef<HTMLInputElement>(null)

  return (
    <div className="space-y-6">
      <HeadingSmall
        title={t("components.delete_account.title")}
        description={t("components.delete_account.description")}
      />
      <div className="space-y-4 rounded-lg border border-red-100 bg-red-50 p-4 dark:border-red-200/10 dark:bg-red-700/10">
        <div className="relative space-y-0.5 text-red-600 dark:text-red-100">
          <p className="font-medium">
            {t("components.delete_account.warning")}
          </p>
          <p className="text-sm">{t("components.delete_account.caution")}</p>
        </div>

        <AdaptableDialog>
          <AdaptableDialogTrigger asChild>
            <Button>
              {t("components.delete_account.title")}
            </Button>
          </AdaptableDialogTrigger>
          <AdaptableDialogContent
            showCloseButton={false}
            className="p-5 md:p-6"
          >
            <AdaptableDialogTitle>
              {t("components.delete_account.confirm_title")}
            </AdaptableDialogTitle>
            <AdaptableDialogDescription>
              {t("components.delete_account.confirm_description")}
            </AdaptableDialogDescription>
            <Form
              action={users.destroy()}
              options={{
                preserveScroll: true,
              }}
              onError={() => passwordInput.current?.focus()}
              resetOnSuccess
              className="space-y-6"
            >
              {({ resetAndClearErrors, processing, errors }) => (
                <>
                  <Field>
                    <FieldLabel
                      htmlFor="password_challenge"
                      className="sr-only"
                    >
                      {t("common.password")}
                    </FieldLabel>

                    <Input
                      id="password_challenge"
                      type="password"
                      name="password_challenge"
                      ref={passwordInput}
                      placeholder={t("common.password")}
                      autoComplete="current-password"
                    />

                    <FieldError
                      errors={errors.password_challenge?.map((message) => ({
                        message,
                      }))}
                    />
                  </Field>

                  <AdaptableDialogFooter className="p-0 max-md:flex-row max-md:gap-3">
                    <AdaptableDialogClose asChild>
                      <Button
                        variant="secondary"
                        className="max-md:flex-1"
                        onClick={() => resetAndClearErrors()}
                      >
                        {t("common.cancel")}
                      </Button>
                    </AdaptableDialogClose>

                    <Button
                      disabled={processing}
                      asChild
                      className="max-md:flex-1"
                    >
                      <button type="submit">
                        {t("components.delete_account.title")}
                      </button>
                    </Button>
                  </AdaptableDialogFooter>
                </>
              )}
            </Form>
          </AdaptableDialogContent>
        </AdaptableDialog>
      </div>
    </div>
  )
}
