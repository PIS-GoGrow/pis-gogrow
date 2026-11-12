import { useCallback, useEffect, useState } from "react"

import { isBrowser } from "@/lib/browser"
import * as storage from "@/lib/storage"

export type Appearance = "light" | "dark" | "system"

const prefersDark = () =>
  isBrowser && window.matchMedia("(prefers-color-scheme: dark)").matches

const mediaQuery = () =>
  isBrowser ? window.matchMedia("(prefers-color-scheme: dark)") : null

const THEME_COLORS = {
  light: "#fafafa",
  dark: "#171717",
} as const

const setThemeColor = (isDark: boolean) => {
  let meta = document.querySelector<HTMLMetaElement>(
    'meta[name="theme-color"]:not([media])',
  )
  if (!meta) {
    meta = document.createElement("meta")
    meta.name = "theme-color"
    document.head.appendChild(meta)
  }
  meta.content = isDark ? THEME_COLORS.dark : THEME_COLORS.light
}

const applyTheme = (appearance: Appearance) => {
  if (!isBrowser) return

  const isDark =
    appearance === "dark" || (appearance === "system" && prefersDark())

  document.documentElement.classList.toggle("dark", isDark)
  document.documentElement.style.colorScheme = isDark ? "dark" : "light"
  setThemeColor(isDark)
}

const handleSystemThemeChange = () => {
  const currentAppearance = storage.getItem("appearance") as Appearance
  applyTheme(currentAppearance ?? "system")
}

export function initializeTheme() {
  const savedAppearance =
    (storage.getItem("appearance") as Appearance) || "system"

  applyTheme(savedAppearance)

  mediaQuery()?.addEventListener("change", handleSystemThemeChange)
}

export function useAppearance() {
  const [appearance, setAppearance] = useState<Appearance>(() => {
    const saved = storage.getItem("appearance") as Appearance | null
    return saved ?? "system"
  })

  const updateAppearance = useCallback((mode: Appearance) => {
    setAppearance(mode)
    if (mode === "system") {
      storage.removeItem("appearance")
    } else {
      storage.setItem("appearance", mode)
    }
    applyTheme(mode)
  }, [])

  useEffect(() => {
    applyTheme(appearance)

    return () =>
      mediaQuery()?.removeEventListener("change", handleSystemThemeChange)
  }, [appearance])

  return { appearance, updateAppearance } as const
}
