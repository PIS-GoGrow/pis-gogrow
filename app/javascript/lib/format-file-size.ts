const UNITS = ["B", "KB", "MB", "GB"]

export function formatFileSize(bytes: number): string {
  let size = bytes
  let unit = 0

  while (size >= 1024 && unit < UNITS.length - 1) {
    size /= 1024
    unit += 1
  }

  return `${unit === 0 ? size : Number(size.toFixed(1))} ${UNITS[unit]}`
}
