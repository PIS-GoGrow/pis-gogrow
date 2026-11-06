import { usePage } from "@inertiajs/react"
import { useEffect } from "react"

import type { CartItem } from "@/pages/consumer/dashboard/consumer-types"
import type { Session } from "@/types"

import useSessionStorage from "./use-session-storage"

const LEGACY_CART_STORAGE_KEY = "cart"
const CONSUMER_CART_STORAGE_PREFIX = "consumer-cart:"

type CartSession = Pick<Session, "id" | "role">

export function consumerCartStorageKey(session: CartSession) {
  return `${CONSUMER_CART_STORAGE_PREFIX}${session.role}:${session.id}`
}

export function cleanupConsumerCartStorage(
  activeKey: string | null,
  storage: Storage = window.sessionStorage,
) {
  try {
    storage.removeItem(LEGACY_CART_STORAGE_KEY)

    for (let index = storage.length - 1; index >= 0; index -= 1) {
      const key = storage.key(index)
      if (key?.startsWith(CONSUMER_CART_STORAGE_PREFIX) && key !== activeKey) {
        storage.removeItem(key)
      }
    }
  } catch {
    // Storage bloqueado: no hay claves accesibles para limpiar.
  }
}

export function useConsumerCart() {
  const { auth } = usePage().props
  const storageKey = consumerCartStorageKey(auth.session)
  return useSessionStorage<CartItem[]>(storageKey, [])
}

export function useConsumerCartCleanup() {
  const { auth } = usePage().props
  const session = auth?.session
  const activeKey =
    session?.role === "consumer" ? consumerCartStorageKey(session) : null

  useEffect(() => {
    cleanupConsumerCartStorage(activeKey)
  }, [activeKey])
}
