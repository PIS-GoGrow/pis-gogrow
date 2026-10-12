import { Link } from "@inertiajs/react"
import { Search, Trash2, UtensilsCrossed } from "lucide-react"
import { useState } from "react"
import { useTranslation } from "react-i18next"

import { Button } from "@/components/ui/button"
import {
  Card,
  CardDescription,
  CardFooter,
  CardHeader,
  CardTitle,
} from "@/components/ui/card"
import {
  Empty,
  EmptyDescription,
  EmptyHeader,
  EmptyMedia,
  EmptyTitle,
} from "@/components/ui/empty"
import { Input } from "@/components/ui/input"
import { normalizeText } from "@/lib/normalize-text"
import { providerMenus, schedules } from "@/routes"
import type { SavedMenu } from "@/types"

interface SavedMenusListProps {
  menus: SavedMenu[]
  onDelete: (menu: SavedMenu) => void
}

export default function SavedMenusList({
  menus,
  onDelete,
}: SavedMenusListProps) {
  const { t } = useTranslation()
  const [search, setSearch] = useState("")
  // Al editar un plato desde acá, se vuelve a esta pestaña.
  const returnTo = schedules.index({ query: { tab: "saved" } }).url

  const query = normalizeText(search.trim())
  const visible = menus.filter((menu) =>
    normalizeText(menu.name ?? "").includes(query),
  )

  if (menus.length === 0) {
    return (
      <Empty className="border">
        <EmptyHeader>
          <EmptyMedia variant="icon">
            <UtensilsCrossed aria-hidden="true" />
          </EmptyMedia>
          <EmptyTitle>
            {t("pages.schedules.index.saved.empty.title")}
          </EmptyTitle>
          <EmptyDescription>
            {t("pages.schedules.index.saved.empty.description")}
          </EmptyDescription>
        </EmptyHeader>
      </Empty>
    )
  }

  return (
    <>
      <div className="relative">
        <Input
          value={search}
          onChange={(event) => setSearch(event.target.value)}
          placeholder={t("pages.schedules.index.search_placeholder")}
          aria-label={t("pages.schedules.index.search_label")}
          autoComplete="off"
          className="pr-9"
        />
        <Search
          aria-hidden="true"
          className="text-muted-foreground pointer-events-none absolute top-1/2 right-3 size-4 -translate-y-1/2"
        />
      </div>

      {visible.length === 0 ? (
        <Empty className="border">
          <EmptyHeader>
            <EmptyMedia variant="icon">
              <UtensilsCrossed aria-hidden="true" />
            </EmptyMedia>
            <EmptyTitle>
              {t("pages.schedules.index.no_results.title")}
            </EmptyTitle>
            <EmptyDescription>
              {t("pages.schedules.index.no_results.description")}
            </EmptyDescription>
          </EmptyHeader>
        </Empty>
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          {visible.map((menu) => (
            <Card
              key={menu.id}
              className="hover:bg-muted/40 relative w-full transition-colors"
            >
              <CardHeader>
                <CardTitle>
                  <Link
                    href={
                      providerMenus.edit(menu.id, {
                        query: { return_to: returnTo },
                      }).url
                    }
                    aria-label={t("pages.schedules.index.edit_dish", {
                      name: menu.name,
                    })}
                    className="after:absolute after:inset-0 after:rounded-xl"
                  >
                    {menu.name} | {menu.price}$
                  </Link>
                </CardTitle>
                <CardDescription>{menu.description}</CardDescription>
              </CardHeader>
              <CardFooter className="border-t">
                <Button
                  variant="ghost"
                  size="sm"
                  className="text-destructive hover:text-destructive relative z-10"
                  onClick={() => onDelete(menu)}
                >
                  <Trash2 aria-hidden="true" />
                  {t("pages.schedules.index.saved.delete")}
                </Button>
              </CardFooter>
            </Card>
          ))}
        </div>
      )}
    </>
  )
}
