# frozen_string_literal: true

class Admin::AccountSerializer < AccountSerializer
  typelize :string?
  attribute :paid_on do |account|
    payment = approved_payment(account)
    DateFormat.short(payment.created_at) if payment
  end

  typelize :string?
  attribute :receipt_download_url do |account|
    payment = approved_payment(account)
    receipt_admin_payment_path(payment) if payment&.receipt&.attached?
  end

  typelize :string?
  attribute :invoice_download_url do |account|
    invoice = account.invoices.detect(&:approved?)
    file_admin_invoice_path(invoice, download: 1) if invoice
  end

  private

  def approved_payment(account)
    account.payments.select(&:approved?).max_by(&:created_at)
  end
end
