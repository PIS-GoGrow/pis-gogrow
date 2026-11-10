// hooks/use-offline-data-cleanup.ts
import { usePage } from "@inertiajs/react"
import { useEffect } from "react"

import { db } from "@/lib/offline-db"

export function useOfflineDataCleanup() {
  const { auth } = usePage().props
  const sessionId = auth?.session?.id
  const role = auth?.session?.role

  useEffect(() => {
    async function cleanup() {
      // Sin sesión: no debe quedar nada guardado.
      if (sessionId == null || !role) {
        await Promise.all([
          db.provider_orders.clear(),
          db.consumer_orders.clear(),
        ])
        return
      }

      // Tabla del rol que no corresponde a la sesión (o ambas si el rol no
      // tiene datos offline, por ejemplo admin).
      if (role !== "provider") await db.provider_orders.clear()
      if (role !== "consumer") await db.consumer_orders.clear()

      // Misma tabla, pero guardada por otro usuario (dispositivo compartido).
      const table =
        role === "provider"
          ? db.provider_orders
          : role === "consumer"
            ? db.consumer_orders
            : null
      const record = await table?.get(1)
      if (record && record.session_id !== sessionId) await table?.clear()
    }

    cleanup().catch((error) => {
      console.error("No se pudieron limpiar los datos offline", error)
    })
  }, [sessionId, role])
}
