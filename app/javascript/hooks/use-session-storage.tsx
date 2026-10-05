import { useEffect, useState } from "react"

export default function useSessionStorage<T>(key: string, initialValue: T) {
  // Inicialización perezosa: lee de sessionStorage una sola vez
  const [value, setValue] = useState<T>(() => {
    if (typeof window === "undefined") return initialValue // SSR (Inertia SSR)
    try {
      const stored = window.sessionStorage.getItem(key)
      return stored !== null ? (JSON.parse(stored) as T) : initialValue
    } catch {
      return initialValue
    }
  })

  // Persistir en cada cambio
  useEffect(() => {
    try {
      window.sessionStorage.setItem(key, JSON.stringify(value))
    } catch {
      // cuota llena o modo privado: ignorar
    }
  }, [key, value])

  return [value, setValue] as const
}
