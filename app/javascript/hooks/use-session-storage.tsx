import {
  type Dispatch,
  type SetStateAction,
  useCallback,
  useMemo,
  useState,
  useSyncExternalStore,
} from "react"

// Store mínimo: avisa a todos los hooks montados cuando cambia el storage
const listeners = new Set<() => void>()

function subscribe(callback: () => void) {
  listeners.add(callback)
  return () => {
    listeners.delete(callback)
  }
}

function emit() {
  listeners.forEach((listener) => listener())
}

function getRaw(key: string): string | null {
  try {
    return window.sessionStorage.getItem(key)
  } catch {
    // storage bloqueado: tratar como vacío
    return null
  }
}

function parse<T>(raw: string | null, fallback: T): T {
  if (raw === null) return fallback
  try {
    return JSON.parse(raw) as T
  } catch {
    // JSON inválido: usar el valor inicial
    return fallback
  }
}

export default function useSessionStorage<T>(key: string, initialValue: T) {
  // initialValue congelado al montar (evita depender de la identidad de literales)
  const [initial] = useState<T>(initialValue)

  // El snapshot es un string (primitivo), así React compara por valor.
  // En el servidor devuelve null => initialValue, igual que el primer
  // render de hidratación en el cliente: no hay mismatch.
  const raw = useSyncExternalStore(
    subscribe,
    () => getRaw(key),
    () => null,
  )

  // Parsear solo cuando cambia el string: la referencia del objeto es estable
  const value = useMemo(() => parse(raw, initial), [raw, initial])

  const setValue: Dispatch<SetStateAction<T>> = useCallback(
    (next) => {
      const prev = parse(getRaw(key), initial)
      const resolved =
        typeof next === "function" ? (next as (prev: T) => T)(prev) : next

      try {
        if (resolved === undefined) {
          window.sessionStorage.removeItem(key)
        } else {
          window.sessionStorage.setItem(key, JSON.stringify(resolved))
        }
      } catch {
        // cuota llena o modo privado: ignorar
      }
      emit()
    },
    [key, initial],
  )

  const remove = useCallback(() => {
    try {
      window.sessionStorage.removeItem(key)
    } catch {
      // storage no disponible: ignorar
    }
    emit()
  }, [key])

  return [value, setValue, remove] as const
}
