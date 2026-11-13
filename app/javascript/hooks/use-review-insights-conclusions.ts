import { useEffect, useRef, useState } from "react"

import { providerInsights } from "@/routes"

interface Conclusion {
  text: string
  period: { from: string; to: string }
  review_count: number
  generated_by_ai: true
}

type ErrorKind =
  | "insufficient_data"
  | "rate_limited"
  | "invalid_period"
  | "timeout"
  | "unavailable"

function errorKind(code: unknown): ErrorKind {
  if (code === "insufficient_data") return "insufficient_data"
  if (code === "rate_limited") return "rate_limited"
  if (code === "invalid_request" || code === "invalid_period")
    return "invalid_period"
  if (code === "timeout") return "timeout"
  return "unavailable"
}

function isConclusion(
  value: unknown,
  from: string,
  to: string,
): value is Conclusion {
  if (typeof value !== "object" || value === null) return false
  const data = value as Partial<Conclusion>
  return (
    "success" in data &&
    data.success === true &&
    typeof data.text === "string" &&
    data.text.trim().length > 0 &&
    data.period?.from === from &&
    data.period?.to === to &&
    Number.isInteger(data.review_count) &&
    (data.review_count ?? -1) >= 0 &&
    data.generated_by_ai === true
  )
}

export function useReviewInsightsConclusions(from: string, to: string) {
  const [conclusion, setConclusion] = useState<Conclusion | null>(null)
  const [error, setError] = useState<ErrorKind | null>(null)
  const [generating, setGenerating] = useState(false)
  const request = useRef<AbortController | null>(null)

  useEffect(() => () => request.current?.abort(), [])

  function cancel() {
    request.current?.abort()
    request.current = null
    setConclusion(null)
    setError(null)
    setGenerating(false)
  }

  async function generate() {
    if (request.current) return
    const controller = new AbortController()
    request.current = controller
    setGenerating(true)
    setConclusion(null)
    setError(null)

    try {
      const response = await fetch(providerInsights.createConclusions().url, {
        method: "POST",
        credentials: "same-origin",
        signal: controller.signal,
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          "X-CSRF-Token":
            document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')
              ?.content ?? "",
        },
        body: JSON.stringify({ desde: from, hasta: to }),
      })
      if (controller.signal.aborted) return
      if (response.status === 429) {
        setError("rate_limited")
        return
      }

      const data: unknown = await response.json()
      if (controller.signal.aborted) return
      if (!response.ok) {
        const code =
          typeof data === "object" && data !== null && "error" in data
            ? (data.error as { code?: unknown } | null)?.code
            : undefined
        setError(errorKind(code))
      } else if (isConclusion(data, from, to)) {
        setConclusion(data)
      } else {
        setError("unavailable")
      }
    } catch {
      if (!controller.signal.aborted) setError("unavailable")
    } finally {
      if (!controller.signal.aborted) {
        request.current = null
        setGenerating(false)
      }
    }
  }

  return { conclusion, error, generating, generate, cancel }
}
