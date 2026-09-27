# frozen_string_literal: true

class Provider::CollectionOrderSerializer < ApplicationSerializer
  typelize_from Order

  attributes :id, :amount

  typelize :string
  attribute :menu_name do |order|
    order.schedule&.menu&.name.to_s
  end

  typelize :string
  attribute :consumer_name do |order|
    order.consumer.user.name
  end

  typelize :string, nullable: true
  attribute :delivery_date do |order|
    order.schedule&.date&.strftime("%d/%m/%y")
  end

  # Lo que paga el empleado.
  typelize :number
  attribute :charged do |order|
    (order.discounted_price || order.price).to_f
  end

  # Lo que cubre la empresa.
  typelize :number
  attribute :subsidy do |order|
    order.subsidy.to_f
  end
end
