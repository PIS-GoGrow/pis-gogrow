import { router } from "@inertiajs/react"

import { favorite } from "@/routes"

export type FavoriteKind = "menus" | "providers"

export function toggleFavorite(
  kind: FavoriteKind,
  id: number,
  isFavorite: boolean,
) {
  const route = favorite({ kind, id })

  router.visit(route.url, {
    method: isFavorite ? "delete" : route.method,
    preserveScroll: true,
    preserveState: true,
    only: ["favorites", "frequent"],
  })
}
