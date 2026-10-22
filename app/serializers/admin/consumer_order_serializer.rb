# frozen_string_literal: true

class Admin::ConsumerOrderSerializer < ApplicationSerializer
  typelize_from Order

  attributes :id, :amount

  # Formateada en el servidor: el SSR corre en UTC y el cliente no.
  typelize :string, nullable: true
  attribute :date do |order|
    order.delivery_date&.strftime("%-d/%-m")
  end

  typelize :string?
  attribute :provider_name do |order|
    order.schedule&.menu&.provider&.user&.name
  end

  typelize :number
  attribute :subsidy do |order|
    (order.subsidy || 0).to_f
  end

  typelize :number
  attribute :charged do |order|
    (order.discounted_price || order.price).to_f
  end
end
