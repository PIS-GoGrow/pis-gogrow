import { type ClassValue, clsx } from "clsx"
import { twMerge } from "tailwind-merge"

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
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
