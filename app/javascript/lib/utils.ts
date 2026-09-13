import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

// Decimal columns can reach the frontend as strings ("300.0"), so accept both.
export function formatPrice(value: number | string) {
  const amount = Number(value)

  return `$${amount.toLocaleString("es-UY", {
    minimumFractionDigits: Number.isInteger(amount) ? 0 : 2,
    maximumFractionDigits: 2,
  })}`
}

// The Google sign-in button is a native <form> POST (not an Inertia visit),
// so it needs the CSRF token read from the page instead of Inertia adding
// it automatically.
export function readAuthenticityToken() {
  if (typeof document === "undefined") return ""

  return (
    document
      .querySelector('meta[name="csrf-token"]')
      ?.getAttribute("content") ?? ""
  )
}
