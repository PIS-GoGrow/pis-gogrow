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
    invoice = account.invoices.detect { it.pending? || it.approved? }
    file_admin_invoice_path(invoice, download: 1) if invoice
  end

  # Solo viene cuando hay que esperar para volver a recordar la factura.
  typelize :string?
  attribute :invoice_reminder_available_at do |account|
    last_sent_at = params[:invoice_reminders]&.[](account.id)
    eligibility = InvoiceReminders::Eligibility.new(account:, last_sent_at:)
    next unless eligibility.reason == :cooldown

    DateFormat.long_with_time(eligibility.next_available_at.in_time_zone(Time.zone), inline: true)
  end

  private

  def approved_payment(account)
    account.payments.select(&:approved?).max_by(&:created_at)
  end
end
