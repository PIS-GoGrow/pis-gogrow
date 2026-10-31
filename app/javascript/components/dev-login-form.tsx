import { Form } from "@inertiajs/react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import { Field, FieldGroup, FieldLabel } from "@/components/ui/field"
import { Input } from "@/components/ui/input"
import { Spinner } from "@/components/ui/spinner"
import { sessions } from "@/routes"

interface Props {
  origin?: string
}

export default function DevLoginForm({ origin }: Props) {
  const { t } = useTranslation()

  return (
    <>
      <div className="flex items-center gap-3">
        <span className="bg-border h-px flex-1" />
        <span className="text-muted-foreground text-xs uppercase">
          {t("pages.sessions.new.or")}
        </span>
        <span className="bg-border h-px flex-1" />
      </div>

      {/*
        Las credenciales incorrectas vuelven como flash, no como errores de
        campo: sessions#create redirige con alert en lugar de renderizar.
      */}
      <Form
        action={sessions.create()}
        resetOnSuccess={["password"]}
        disableWhileProcessing
        noValidate
        className="flex flex-col gap-6"
      >
        {({ processing }) => (
          <FieldGroup>
            {origin && <input type="hidden" name="origin" value={origin} />}
            <Field>
              <FieldLabel htmlFor="email">
                {t("common.email_address")}
              </FieldLabel>
              <Input
                id="email"
                type="email"
                name="email"
                required
                autoComplete="email"
                placeholder={t("common.email_placeholder")}
              />
            </Field>

            <Field>
              <FieldLabel htmlFor="password">{t("common.password")}</FieldLabel>
              <Input
                id="password"
                type="password"
                name="password"
                required
                autoComplete="current-password"
              />
            </Field>

            <Button type="submit" className="w-full">
              {processing && <Spinner />}
              {t("pages.sessions.new.submit")}
            </Button>
          </FieldGroup>
        )}
      </Form>
    </>
  )
}
