# frozen_string_literal: true

# El comprobante en sí (verlo, aprobarlo o rechazarlo) es alcance de IBP-060:
# Acá se exponen los datos necesarios para mostrar el historial y acceder
# a los comprobantes asociados a cada pago.
class Provider::CollectionPaymentSerializer < ApplicationSerializer
  typelize_from Payment

  attributes :id, :status, :rejection_reason

  typelize :string
  attribute :date do |payment|
    payment.created_at.strftime("%d/%m/%y")
  end

  typelize :string, nullable: true
  attribute :receipt_url do |payment|
    next unless payment.receipt.attached?

    Rails.application.routes.url_helpers.receipt_provider_payment_path(payment)
  end

  typelize :string, nullable: true
  attribute :receipt_filename do |payment|
    payment.receipt.filename.to_s if payment.receipt.attached?
  end

  typelize :string, nullable: true
  attribute :receipt_content_type do |payment|
    payment.receipt.content_type if payment.receipt.attached?
  end
end
