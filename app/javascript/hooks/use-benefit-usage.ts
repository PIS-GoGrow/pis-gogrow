import { useEffect, useRef, useState } from "react"

import { adminBenefitUsage } from "@/routes"
import type {
  BenefitUsageStats,
  BenefitUsageSummary,
} from "@/types/benefit-usage"

export function useBenefitUsage(month: string) {
  const [stats, setStats] = useState<BenefitUsageStats | null>(null)
  const [error, setError] = useState(false)
  const [attempt, setAttempt] = useState(0)
  const [summary, setSummary] = useState<string | null>(null)
  const [summaryError, setSummaryError] = useState<string | null>(null)
  const [generating, setGenerating] = useState(false)
  const statsRequest = useRef<AbortController | null>(null)
  const summaryRequest = useRef<AbortController | null>(null)

  useEffect(() => {
    const request = new AbortController()
    statsRequest.current = request
    // StrictMode desmonta el primer efecto antes de esta microtarea: no enviamos dos GET.
    void Promise.resolve().then(async () => {
      if (request.signal.aborted) return
      try {
        const response = await fetch(
          adminBenefitUsage.show({ query: { month } }).url,
          {
            credentials: "same-origin",
            signal: request.signal,
            headers: { Accept: "application/json" },
          },
        )
        if (!response.ok) throw new Error("Statistics unavailable")
        const data = (await response.json()) as BenefitUsageStats
        if (data.schema_version !== 1 || data.period.month !== month)
          throw new Error("Unexpected period")
        if (!request.signal.aborted) setStats(data)
      } catch {
        if (!request.signal.aborted) setError(true)
      }
    })
    return () => {
      request.abort()
      summaryRequest.current?.abort()
    }
  }, [month, attempt])

  function retry() {
    setError(false)
    setStats(null)
    setAttempt((value) => value + 1)
  }

  function cancel() {
    statsRequest.current?.abort()
    summaryRequest.current?.abort()
    summaryRequest.current = null
    setSummary(null)
    setSummaryError(null)
    setGenerating(false)
  }

  async function generate() {
    if (summaryRequest.current || !stats) return
    const request = new AbortController()
    summaryRequest.current = request
    setGenerating(true)
    setSummary(null)
    setSummaryError(null)
    try {
      const response = await fetch(adminBenefitUsage.createSummary().url, {
        method: "POST",
        credentials: "same-origin",
        signal: request.signal,
        headers: {
          Accept: "application/json",
          "Content-Type": "application/json",
          "X-CSRF-Token":
            document.querySelector<HTMLMetaElement>('meta[name="csrf-token"]')
              ?.content ?? "",
        },
        body: JSON.stringify({ month }),
      })
      if (request.signal.aborted) return
      if (response.status === 429) {
        setSummaryError("rate_limited")
        return
      }
      const data = (await response.json()) as
        BenefitUsageSummary | { success: false; error: { code: string } }
      if (request.signal.aborted) return
      if (!response.ok || !data.success) {
        setSummaryError(
          !data.success && data.error.code === "configuration_missing"
            ? "configuration_missing"
            : "summary_unavailable",
        )
      } else if (data.month === month && typeof data.text === "string") {
        setSummary(data.text)
      } else {
        setSummaryError("summary_unavailable")
      }
    } catch {
      if (!request.signal.aborted) setSummaryError("summary_unavailable")
    } finally {
      if (!request.signal.aborted) {
        summaryRequest.current = null
        setGenerating(false)
      }
    }
  }

  return {
    stats,
    error,
    retry,
    summary,
    summaryError,
    generating,
    generate,
    cancel,
  }
}
