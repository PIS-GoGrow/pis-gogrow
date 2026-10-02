# frozen_string_literal: true

# El comprobante en sí (verlo, aprobarlo o rechazarlo) es alcance de IBP-060:
# acá el pago solo aporta su estado y cuándo se informó.
class Provider::CollectionPaymentSerializer < ApplicationSerializer
  typelize_from Payment

  attributes :id, :status

  typelize :string
  attribute :date do |payment|
    payment.created_at.strftime("%d/%m/%y")
  end
end
