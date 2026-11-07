import { router } from "@inertiajs/react"
import { useEffect, useRef } from "react"
import { useTranslation } from "react-i18next"
import { toast } from "sonner"

// Un id fijo para que los avisos se reemplacen en lugar de apilarse: un solo
// toque en la barra inferior dispara la visita y además el prefetch del link, y
// sin conexión fallan los dos.
const TOAST_ID = "network-status"

// Inertia avisa del error de red y después rechaza la promesa de la visita.
// Rechazarla no sobra: es así como descarta el prefetch que quedó en vuelo, y
// si se lo tapamos el link queda esperando para siempre una respuesta que no
// llega. Lo único que sobra es el "Uncaught (in promise)" en la consola, así
// que la marcamos como atendida sin meternos en el manejo de Inertia.
function isNetworkError(reason: unknown) {
  return reason instanceof Error && reason.name === "HttpNetworkError"
}

export function useNetworkStatus() {
  const { t } = useTranslation()
  // Avisar que volvió la conexión solo le sirve a quien vio que se cortó.
  const warned = useRef(false)

  useEffect(() => {
    const stopListening = router.on("networkError", () => {
      warned.current = true

      toast.error(t("components.network_status.offline.title"), {
        id: TOAST_ID,
        description: t("components.network_status.offline.description"),
        // Arriba y no abajo como el resto: en mobile el aviso se queda en
        // pantalla y abajo taparía la barra de navegación, que es justo lo que
        // el usuario está tratando de usar.
        position: "top-center",
        // Sin internet el aviso queda hasta que vuelva la conexión. Si el
        // navegador dice que hay red, el corte puede ser momentáneo y alcanza
        // con avisar una vez.
        duration: navigator.onLine ? undefined : Infinity,
      })
    })

    function silenceRejection(event: PromiseRejectionEvent) {
      if (isNetworkError(event.reason)) event.preventDefault()
    }

    function announceRecovery() {
      if (!warned.current) return
      warned.current = false

      toast.dismiss(TOAST_ID)
      toast.success(t("components.network_status.online.title"), {
        description: t("components.network_status.online.description"),
        position: "top-center",
      })
    }

    window.addEventListener("unhandledrejection", silenceRejection)
    window.addEventListener("online", announceRecovery)

    return () => {
      stopListening()
      window.removeEventListener("unhandledrejection", silenceRejection)
      window.removeEventListener("online", announceRecovery)
    }
  }, [t])
}
