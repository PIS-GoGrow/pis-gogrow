export const passwordRules = [
  { key: "min_length", test: (password: string) => password.length >= 16 },
  { key: "uppercase", test: (password: string) => /[A-Z]/.test(password) },
  { key: "number", test: (password: string) => /\d/.test(password) },
  {
    key: "special",
    test: (password: string) => /[^\p{L}\p{N}]/u.test(password),
  },
] as const

export function isStrongPassword(password: string) {
  return passwordRules.every((rule) => rule.test(password))
}
