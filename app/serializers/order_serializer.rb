# frozen_string_literal: true

class OrderSerializer < ApplicationSerializer
  typelize_from Order

  attributes :id, :status, :amount, :notes, :address

  typelize :string?
  attribute :date do |order|
    order.schedule&.date&.iso8601
  end

  typelize :string?
  attribute :menu_name do |order|
    order.schedule&.menu&.name
  end

  # El proveedor no tiene nombre propio: se identifica por el del usuario dueño.
  typelize :string?
  attribute :provider_name do |order|
    order.schedule&.menu&.provider&.user&.name
  end

  # to_f y no el decimal crudo: Alba serializa BigDecimal como string y el tipo
  # generado diría number. En el cliente solo se formatea, no se opera.
  typelize :number?
  attribute :price do |order|
    order.price&.to_f
  end

  typelize :number?
  attribute :discounted_price do |order|
    order.discounted_price&.to_f
  end

  typelize :number?
  attribute :subsidy do |order|
    order.subsidy&.to_f
  end
end
