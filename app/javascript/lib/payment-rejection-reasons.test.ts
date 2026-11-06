import { describe, expect, it } from "vitest"

import {
  PARTIAL_PAYMENT_REJECTION_REASON,
  paymentPresentationStatus,
  pendingRejectionReason,
} from "./payment-rejection-reasons"

describe("pendingRejectionReason", () => {
  it("returns null when there are no payments", () => {
    expect(pendingRejectionReason([])).toBeNull()
  })

  it("returns null when no payment has been rejected", () => {
    expect(
      pendingRejectionReason([{ status: "submitted", rejection_reason: null }]),
    ).toBeNull()
  })

  it("returns the rejection reason of a rejected payment", () => {
    expect(
      pendingRejectionReason([
        { status: "rejected", rejection_reason: "Comprobante ilegible" },
      ]),
    ).toBe("Comprobante ilegible")
  })

  it("returns the rejection reason of the rejected payment even when a newer receipt is submitted", () => {
    expect(
      pendingRejectionReason([
        { status: "submitted", rejection_reason: null },
        { status: "rejected", rejection_reason: "Monto no coincide" },
      ]),
    ).toBe("Monto no coincide")
  })

  it("returns the latest rejection reason when there are multiple rejections and a newer submitted receipt", () => {
    expect(
      pendingRejectionReason([
        { status: "submitted", rejection_reason: null },
        {
          status: "rejected",
          rejection_reason: "Segundo rechazo: datos incorrectos",
        },
        { status: "rejected", rejection_reason: "Primer rechazo: borroso" },
      ]),
    ).toBe("Segundo rechazo: datos incorrectos")
  })

  it("returns null once an approved payment is present regardless of earlier rejections", () => {
    expect(
      pendingRejectionReason([
        { status: "approved", rejection_reason: null },
        { status: "rejected", rejection_reason: "Comprobante ilegible" },
      ]),
    ).toBeNull()
  })
})

describe("paymentPresentationStatus", () => {
  it("maps rejected with partial payment reason to partial presentation status", () => {
    expect(
      paymentPresentationStatus({
        status: "rejected",
        rejection_reason: PARTIAL_PAYMENT_REJECTION_REASON,
      }),
    ).toBe("partial")
  })

  it("retains rejected status for any other rejection reason", () => {
    expect(
      paymentPresentationStatus({
        status: "rejected",
        rejection_reason: "Comprobante no válido",
      }),
    ).toBe("rejected")
  })

  it("leaves other statuses unchanged", () => {
    expect(
      paymentPresentationStatus({
        status: "submitted",
        rejection_reason: null,
      }),
    ).toBe("submitted")
  })
})
