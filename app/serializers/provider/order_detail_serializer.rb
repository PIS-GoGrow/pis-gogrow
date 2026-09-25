# frozen_string_literal: true

# El detalle agrega lo que el proveedor necesita para decidir y preparar: con
# quién es el pedido, qué lleva el plato y cuánto cupo queda del día.
class Provider::OrderDetailSerializer < Provider::OrderSerializer
  typelize :string, nullable: true
  attribute :date do |order|
    order.schedule&.date&.iso8601
  end

  typelize_from Order
  attributes :delivery_method

  typelize :string, nullable: true
  attribute :consumer_company do |order|
    order.consumer.company&.name
  end

  typelize :string
  attribute :consumer_email do |order|
    order.consumer.user.email
  end

  typelize :string, nullable: true
  attribute :menu_description do |order|
    order.schedule&.menu&.description
  end

  typelize "string[]"
  attribute :menu_sauces do |order|
    order.schedule&.menu&.sauces || []
  end

  typelize "string[]"
  attribute :menu_fillings do |order|
    order.schedule&.menu&.fillings || []
  end

  typelize :number, nullable: true
  attribute :discounted_price do |order|
    order.discounted_price&.to_f
  end

  typelize :number, nullable: true
  attribute :subsidy do |order|
    order.subsidy&.to_f
  end

  # Cupo del día del plato: cuánto se publicó y cuánto queda sin comprometer.
  typelize :number, nullable: true
  attribute :schedule_amount do |order|
    order.schedule&.amount
  end

  typelize :number, nullable: true
  attribute :remaining_amount do |order|
    order.schedule&.remaining_amount
  end

  typelize :string, nullable: true
  attribute :rejection_reason do |order|
    order.rejection_reason
  end

  typelize :string, nullable: true
  attribute :rejection_details do |order|
    order.rejection_details
  end
end
