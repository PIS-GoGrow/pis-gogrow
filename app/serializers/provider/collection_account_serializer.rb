# frozen_string_literal: true

# Serializa una ProviderCollectionSummary::AccountRow: la cuenta más las viandas
# que la forman, que se calculan para todas las cuentas de una vez.
class Provider::CollectionAccountSerializer < ApplicationSerializer
  typelize id: :number, owner_name: :string, meals: :number
  attributes :id, :owner_name, :meals

  typelize :number
  attribute :amount do |row|
    row.amount.to_f
  end

  typelize "'consumer' | 'company'"
  attribute :source do |row|
    row.company? ? "company" : "consumer"
  end

  # El estado del cobro es el del último comprobante, así que sigue el enum de
  # Payment; escrito a mano porque acá no hay un modelo del que inferirlo.
  typelize "'pending' | 'submitted' | 'approved' | 'rejected'"
  attribute :status, &:collection_status

  typelize :boolean
  attribute :can_approve_payment do |row|
    row.collection_status == "submitted" && !row.account.current?
  end

  typelize :boolean
  attribute :overdue, &:overdue?

  typelize "{ eligible: boolean; remaining: number; next_available_at: string | null; blocked_reason: string | null }"
  attribute :debt_reminder do |row|
    notifications = row.reminder_notifications
    if row.account.owner_type == "Consumer"
      notifications = notifications.select { it.user_id == row.account.owner.user_id }
    end
    eligibility = DebtReminders::Eligibility.new(account: row.account, notifications:)

    {
      eligible: eligibility.eligible?,
      remaining: eligibility.remaining,
      next_available_at: eligibility.next_available_at&.in_time_zone(Time.zone)&.strftime("%d/%m/%Y a las %H:%M"),
      blocked_reason: eligibility.reason&.to_s
    }
  end

  # Formateadas en el servidor: el SSR corre en UTC y el cliente no.
  typelize :string
  attribute :month do |row|
    I18n.l(row.month, format: :month_name_year)
  end

  typelize :string
  attribute :due_date do |row|
    row.due_date.strftime("%d/%m/%y")
  end

  typelize :string, nullable: true
  attribute :paid_on do |row|
    row.paid_on&.strftime("%d/%m/%y")
  end

  # El pago que hay que revisar: el más viejo en submitted si hay alguno sin
  # resolver (ver Account#payment_pending_review), o el último si no hay nada
  # pendiente (para mostrar, por ejemplo, el motivo de un rechazo).
  typelize :number, nullable: true
  attribute :payment_id do |row|
    row.account.payment_pending_review&.id || row.account.last_payment&.id
  end

  typelize :string, nullable: true
  attribute :receipt_url do |row|
    payment = row.account.payment_pending_review || row.account.last_payment
    next unless payment&.receipt&.attached?

    Rails.application.routes.url_helpers.receipt_provider_payment_path(payment)
  end

  typelize :string, nullable: true
  attribute :receipt_content_type do |row|
    payment = row.account.payment_pending_review || row.account.last_payment
    payment.receipt.content_type if payment&.receipt&.attached?
  end

  # Solo la cuenta de la empresa lleva factura: es la que le cobra el subsidio a GoGrow.
  typelize invoice: [ nullable: true ]
  has_one :latest_invoice, key: :invoice, resource: Provider::InvoiceSerializer
  has_many :orders, resource: Provider::CollectionOrderSerializer
  has_many :payments, resource: Provider::CollectionPaymentSerializer
end
