import { renderHook } from "@testing-library/react"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

import { useNetworkStatus } from "./use-network-status"

interface ToastOptions {
  position?: string
  id?: string
  description?: string
  duration?: number
}

const toast = vi.hoisted(() => ({
  error: vi.fn<(message: string, options: ToastOptions) => void>(),
  success: vi.fn<(message: string, options: ToastOptions) => void>(),
  dismiss: vi.fn<(id: string) => void>(),
}))
vi.mock("sonner", () => ({ toast }))

const stopListening = vi.hoisted(() => vi.fn())
const router = vi.hoisted(() => ({ on: vi.fn(() => stopListening) }))
vi.mock("@inertiajs/react", () => ({ router }))

// El callback que la app le dejó a Inertia para los errores de red.
function failRequest() {
  const [event, callback] = router.on.mock.calls[0] as [
    string,
    () => boolean | void,
  ]
  expect(event).toBe("networkError")
  return callback()
}

function rejectWith(reason: unknown) {
  const event = Object.assign(
    new Event("unhandledrejection", { cancelable: true }),
    { reason },
  )
  window.dispatchEvent(event)
  return event.defaultPrevented
}

function setOnline(online: boolean) {
  Object.defineProperty(navigator, "onLine", {
    configurable: true,
    value: online,
  })
}

describe("useNetworkStatus", () => {
  beforeEach(() => {
    vi.clearAllMocks()
    setOnline(true)
  })

  afterEach(() => {
    setOnline(true)
  })

  it("avisa con un mensaje entendible cuando la consulta no sale a la red", () => {
    renderHook(() => useNetworkStatus())

    failRequest()

    expect(toast.error).toHaveBeenCalledWith(
      "Sin conexión a internet",
      expect.objectContaining({
        description:
          "No pudimos cargar la página. Revisá tu conexión y volvé a intentar.",
      }),
    )
  })

  it("deja el aviso en pantalla mientras no haya internet", () => {
    setOnline(false)
    renderHook(() => useNetworkStatus())

    failRequest()

    expect(toast.error).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ duration: Infinity }),
    )
  })

  it("no insiste con el aviso cuando el navegador cree que hay conexión", () => {
    renderHook(() => useNetworkStatus())

    failRequest()

    expect(toast.error).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ duration: undefined }),
    )
  })

  it("pone el aviso arriba para no taparle al usuario la barra de navegación", () => {
    setOnline(false)
    renderHook(() => useNetworkStatus())

    failRequest()
    window.dispatchEvent(new Event("online"))

    expect(toast.error).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ position: "top-center" }),
    )
    expect(toast.success).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ position: "top-center" }),
    )
  })

  it("reemplaza el aviso anterior en vez de apilar uno por cada pedido caído", () => {
    renderHook(() => useNetworkStatus())

    failRequest()
    failRequest()

    const ids = toast.error.mock.calls.map(([, options]) => options.id)
    expect(ids).toEqual([ids[0], ids[0]])
    expect(ids[0]).toBeTruthy()
  })

  it("deja que Inertia siga manejando el error para que no se le trabe el prefetch", () => {
    renderHook(() => useNetworkStatus())

    // Cancelar el evento le impediría a Inertia descartar el prefetch en vuelo,
    // y el link quedaría esperando una respuesta que no llega nunca.
    expect(failRequest()).not.toBe(false)
  })

  it("da por atendida la promesa rechazada del error de red", () => {
    renderHook(() => useNetworkStatus())

    const error = new Error("Network error (http://localhost:3025/pedidos)")
    error.name = "HttpNetworkError"

    expect(rejectWith(error)).toBe(true)
  })

  it("no tapa ninguna otra promesa rechazada", () => {
    renderHook(() => useNetworkStatus())

    expect(rejectWith(new TypeError("undefined is not a function"))).toBe(false)
    expect(rejectWith("algo que no es un error")).toBe(false)
  })

  it("avisa cuando vuelve la conexión a quien vio que se cortó", () => {
    setOnline(false)
    renderHook(() => useNetworkStatus())
    failRequest()

    setOnline(true)
    window.dispatchEvent(new Event("online"))

    expect(toast.dismiss).toHaveBeenCalledWith(toast.error.mock.calls[0][1].id)
    expect(toast.success).toHaveBeenCalledWith(
      "Volvió la conexión",
      expect.objectContaining({ description: "Ya podés seguir navegando." }),
    )
  })

  it("no festeja la conexión si nunca se cortó nada", () => {
    renderHook(() => useNetworkStatus())

    window.dispatchEvent(new Event("online"))

    expect(toast.success).not.toHaveBeenCalled()
  })

  it("avisa una sola vez por corte", () => {
    renderHook(() => useNetworkStatus())
    failRequest()

    window.dispatchEvent(new Event("online"))
    window.dispatchEvent(new Event("online"))

    expect(toast.success).toHaveBeenCalledTimes(1)
  })

  it("se desengancha de Inertia y del navegador al desmontarse", () => {
    const { unmount } = renderHook(() => useNetworkStatus())

    unmount()
    const error = new Error("Network error")
    error.name = "HttpNetworkError"

    expect(stopListening).toHaveBeenCalled()
    expect(rejectWith(error)).toBe(false)
  })
})
