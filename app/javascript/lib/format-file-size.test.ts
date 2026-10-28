import { describe, expect, it } from "vitest"

import { formatFileSize } from "./format-file-size"

describe("formatFileSize", () => {
  it("keeps bytes below one kilobyte", () => {
    expect(formatFileSize(0)).toBe("0 B")
    expect(formatFileSize(512)).toBe("512 B")
  })

  it("uses one decimal for kilobytes and megabytes", () => {
    expect(formatFileSize(1536)).toBe("1.5 KB")
    expect(formatFileSize(1258291)).toBe("1.2 MB")
  })

  it("drops the decimal when the value is whole", () => {
    expect(formatFileSize(1024)).toBe("1 KB")
    expect(formatFileSize(10 * 1024 * 1024)).toBe("10 MB")
  })

  it("stops at gigabytes", () => {
    expect(formatFileSize(5 * 1024 ** 3)).toBe("5 GB")
    expect(formatFileSize(2048 * 1024 ** 3)).toBe("2048 GB")
  })
})
