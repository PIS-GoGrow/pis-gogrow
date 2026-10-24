# frozen_string_literal: true

class Admin::ConsumerOrderSerializer < ApplicationSerializer
  typelize_from Order

  attributes :id, :amount

  typelize :number, nullable: true
  attribute :provider_id do |order|
    order[:provider_id] || order.schedule&.menu&.provider_id
  end

  # Formateada en el servidor: el SSR corre en UTC y el cliente no.
  typelize :string, nullable: true
  attribute :date do |order|
    DateFormat.short(order.delivery_date || order.created_at)
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
